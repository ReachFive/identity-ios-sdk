import Foundation
import BrightFutures

enum State {
    case NotInitialized
    case Initialized
}

public typealias PasswordlessCallback = (_ result: Result<AuthToken, ReachFiveError>) -> Void

/// ReachFive identity SDK
public class ReachFive: NSObject {
    let notificationPasswordlessName = Notification.Name("PasswordlessNotification")
    var passwordlessCallback: PasswordlessCallback? = nil
    var state: State = .NotInitialized
    let sdkConfig: SdkConfig
    let providersCreators: Array<ProviderCreator>
    let reachFiveApi: ReachFiveApi
    var providers: [Provider] = []
    internal var scope: [String] = []
    internal let storage: Storage
    let codeResponseType = "code"
    
    public init(sdkConfig: SdkConfig, providersCreators: Array<ProviderCreator>, storage: Storage?) {
        self.sdkConfig = sdkConfig
        self.providersCreators = providersCreators
        self.reachFiveApi = ReachFiveApi(sdkConfig: sdkConfig)
        self.storage = storage ?? UserDefaultsStorage()
    }
    
    public func logout() -> Future<(), ReachFiveError> {
        return self.providers
            .map { $0.logout() }
            .sequence()
            .flatMap { _ in self.reachFiveApi.logout() }
    }
    
    public func refreshAccessToken(authToken: AuthToken) -> Future<AuthToken, ReachFiveError> {
        let refreshRequest = RefreshRequest(
            clientId: sdkConfig.clientId,
            refreshToken: authToken.refreshToken ?? "",
            redirectUri: sdkConfig.scheme
        )
        return reachFiveApi
            .refreshAccessToken(refreshRequest)
            .flatMap({ AuthToken.fromOpenIdTokenResponseFuture($0) })
    }
    
    public override var description: String {
        return """
        Config: domain=\(sdkConfig.domain), clientId=\(sdkConfig.clientId)
        Providers: \(providers)
        Scope: \(scope.joined(separator: ""))
        """
    }
    
    private func loginCallback(tkn: String, scopes: [String]?, completion: @escaping ((Future<AuthToken, ReachFiveError>) -> Any)) {
        
        var resultAuthToken = Future<AuthToken, ReachFiveError>()
        let pkce = Pkce.generate()
        self.storage.save(key: "CODE_VERIFIER", value: pkce)
        let scope = [String](scopes!).joined(separator: " ")
        let options: [String:String] = [
            "client_id": sdkConfig.clientId,
            "tkn": tkn,
            "response_type": codeResponseType,
            "redirect_uri": sdkConfig.scheme,
            "scope": scope,
            "code_challenge": pkce.codeChallenge,
            "code_challenge_method": pkce.codeChallengeMethod
        ]
        // Build redirectUri
        let redirectUri = self.reachFiveApi
            .authorize(options: options)
        // Pass the redirectUri to Safari to get code
        let redirectionSafari = RedirectionSafari(url: redirectUri)
        redirectionSafari.login().onComplete { result in
            
            let code =  redirectionSafari.handleResult(result: result)
            resultAuthToken = self.authWithCode(code: code, pkce: pkce)
            // return authToken with completion
            _ = completion(resultAuthToken)
        }
    }
    
    public func authWithCode(code: String, pkce :Pkce) -> Future<AuthToken, ReachFiveError> {
        let authCodeRequest = AuthCodeRequest(
            clientId: self.sdkConfig.clientId ,
            code: code,
            redirectUri: self.sdkConfig.scheme,
            pkce: pkce
        )
        return self.reachFiveApi
            .authWithCode(authCodeRequest: authCodeRequest)
            .flatMap({ AuthToken.fromOpenIdTokenResponseFuture($0) })
    }
    
    public func signupWithWebAuthn(profile: ProfileWebAuthnSignupRequest,origin: String,friendlyName: String?,viewController: UIViewController,scopes: [String]?, completion: @escaping ((Future<AuthToken, ReachFiveError>) -> Any)) {
        let webAuthnRegistrationRequest = WebAuthnRegistrationRequest(
            origin: origin,
            friendlyName: friendlyName ?? "",
            profile: profile,
            clientId: sdkConfig.clientId
        )
        // get registrationOptions
        self.reachFiveApi
            .createWebAuthnSignupOptions(webAuthnRegistrationRequest: webAuthnRegistrationRequest)
            .onSuccess{registrationOptions in
                // prepare and setup the reachFiveClientFido
                let reachFiveClientFido = ReachFiveFidoClient (viewController: viewController, origin: origin)
                reachFiveClientFido.setupWebAuthnClient()
                reachFiveClientFido.startRegistration(registrationOption: registrationOptions).onSuccess{ webauthnSignupCredential in
                    // start the onSignupWithWebAuthnResult func to get firstly the authenticationToken and then exchange the tkn with an access token
                    self.onSignupWithWebAuthnResult(webauthnSignupCredential: webauthnSignupCredential,scopes: scopes)
                    { (authToken) -> Any in
                        _ = completion(authToken)
                    }
                }
            }.onFailure { error in
                let thePromise = BrightFutures.Promise<AuthToken, ReachFiveError>()
                thePromise.failure(error)
                _ = completion(thePromise.future)
            }
    }
    
    private func onSignupWithWebAuthnResult(webauthnSignupCredential: WebauthnSignupCredential,scopes: [String]?, completion: @escaping ((Future<AuthToken, ReachFiveError>) -> Any)) {
        
        self.reachFiveApi
            .signupWithWebAuthn(webauthnSignupCredential: webauthnSignupCredential)
            .onSuccess{authenticationToken in
                // exchange the tkn with an access token
                self.loginCallback(tkn: authenticationToken.tkn,scopes:scopes){ (authToken) -> Any in
                    _ = completion(authToken)
                }
            }
            .onFailure { error in
                let thePromise = BrightFutures.Promise<AuthToken, ReachFiveError>()
                thePromise.failure(error)
                _ = completion(thePromise.future)
            }
    }
    
    public func loginWithWebAuthn(email: String, origin: String, scopes: [String]?,viewController: UIViewController, completion: @escaping ((Future<AuthToken, ReachFiveError>) -> Any)) {
        
        let webAuthnLoginRequest = WebAuthnLoginRequest(
            clientId: sdkConfig.clientId,
            origin: origin,
            email: email,
            scope: [String](scopes!).joined(separator: " ")
        )
        
        self.reachFiveApi
            .createWebAuthnAuthenticationOptions(webAuthnLoginRequest: webAuthnLoginRequest)
            .onSuccess { authenticationOptions in
                
                let reachFiveClientFido = ReachFiveFidoClient (viewController: viewController, origin: origin)
                reachFiveClientFido.setupWebAuthnClient()
                reachFiveClientFido.startAuthentication(authenticationOptions: authenticationOptions).onSuccess{ authenticationPublicKeyCredential in
                    
                    self.onLoginWithWebAuthnResult(authenticationPublicKeyCredential: authenticationPublicKeyCredential,scopes: scopes)
                    { (authToken) -> Any in
                        _ = completion(authToken)
                    }
                }
            }.onFailure { error in
                let thePromise = BrightFutures.Promise<AuthToken, ReachFiveError>()
                thePromise.failure(error)
                _ = completion(thePromise.future)
            }
    }
    
    private func onLoginWithWebAuthnResult(authenticationPublicKeyCredential: AuthenticationPublicKeyCredential, scopes: [String]?, completion: @escaping ((Future<AuthToken, ReachFiveError>) -> Any)) {
        self.reachFiveApi
            .authenticateWithWebAuthn(authenticationPublicKeyCredential: authenticationPublicKeyCredential)
            .onSuccess{authenticationToken in
                
                self.loginCallback(tkn: authenticationToken.tkn,scopes:scopes){ (authToken) -> Any in
                    _ = completion(authToken)
                }
            }
            .onFailure { error in
                let thePromise = BrightFutures.Promise<AuthToken, ReachFiveError>()
                thePromise.failure(error)
                _ = completion(thePromise.future)
            }
    }
    
    public func listWebAuthnDevices(authToken: AuthToken) -> Future<[DeviceCredential], ReachFiveError> {
        
        return self.reachFiveApi
            .getWebAuthnRegistrations(authorization: buildAuthorization(authToken: authToken))
    }
    
    private func buildAuthorization (authToken: AuthToken) -> String {
        return authToken.tokenType! + " " + authToken.accessToken
    }
}
