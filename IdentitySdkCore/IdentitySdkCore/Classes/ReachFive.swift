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
    public let sdkConfig: SdkConfig
    let providersCreators: Array<ProviderCreator>
    let reachFiveApi: ReachFiveApi
    var providers: [Provider] = []
    internal var scope: [String] = []
    public let storage: Storage
    let codeResponseType = "code"
    public let pkceKey = "PASSWORDLESS_PKCE"
    
    public init(sdkConfig: SdkConfig, providersCreators: Array<ProviderCreator>, storage: Storage?) {
        self.sdkConfig = sdkConfig
        self.providersCreators = providersCreators
        self.reachFiveApi = ReachFiveApi(sdkConfig: sdkConfig)
        self.storage = storage ?? UserDefaultsStorage()
    }
    
    public func logout() -> Future<(), ReachFiveError> {
        providers
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
        """
        Config: domain=\(sdkConfig.domain), clientId=\(sdkConfig.clientId)
        Providers: \(providers)
        Scope: \(scope.joined(separator: " "))
        """
    }
    
    public func loginCallback(tkn: String, scopes: [String]?) -> Future<AuthToken, ReachFiveError> {
        let pkce = Pkce.generate()
        let scope = (scopes ?? scope).joined(separator: " ")
        
        return reachFiveApi.loginCallback(loginCallback: LoginCallback(sdkConfig: sdkConfig, scope: scope, pkce: pkce, tkn: tkn))
            .flatMap({ self.authWithCode(code: $0, pkce: pkce) })
    }
    
    public func authWithCode(code: String, pkce: Pkce) -> Future<AuthToken, ReachFiveError> {
        let authCodeRequest = AuthCodeRequest(
            clientId: sdkConfig.clientId,
            code: code,
            redirectUri: sdkConfig.scheme,
            pkce: pkce
        )
        return reachFiveApi
            .authWithCode(authCodeRequest: authCodeRequest)
            .flatMap({ AuthToken.fromOpenIdTokenResponseFuture($0) })
    }
    
    private func onSignupWithWebAuthnResult(webauthnSignupCredential: WebauthnSignupCredential, scopes: [String]?) -> Future<AuthToken, ReachFiveError> {
        reachFiveApi
            .signupWithWebAuthn(webauthnSignupCredential: webauthnSignupCredential)
            .flatMap({ self.loginCallback(tkn: $0.tkn, scopes: scopes) })
    }
    
    private func onLoginWithWebAuthnResult(authenticationPublicKeyCredential: AuthenticationPublicKeyCredential, scopes: [String]?) -> Future<AuthToken, ReachFiveError> {
        reachFiveApi
            .authenticateWithWebAuthn(authenticationPublicKeyCredential: authenticationPublicKeyCredential)
            .flatMap({ self.loginCallback(tkn: $0.tkn, scopes: scopes) })
    }
    
    internal func listWebAuthnDevices(authToken: AuthToken) -> Future<[DeviceCredential], ReachFiveError> {
        reachFiveApi.getWebAuthnRegistrations(authorization: buildAuthorization(authToken: authToken))
    }
    
    private func buildAuthorization(authToken: AuthToken) -> String {
        authToken.tokenType! + " " + authToken.accessToken
    }
    
    public func buildAuthorizeURL(pkce: Pkce, state: String? = nil, nonce: String? = nil, scope: [String]? = nil) -> URL {
        let scope = (scope ?? self.scope).joined(separator: " ")
        var options = [
            "client_id": sdkConfig.clientId,
            "redirect_uri": sdkConfig.redirectUri,
            "response_type": codeResponseType,
            "scope": scope,
            "code_challenge": pkce.codeChallenge,
            "code_challenge_method": pkce.codeChallengeMethod
        ]
        if let state {
            options["state"] = state
        }
        if let nonce {
            options["nonce"] = nonce
        }
        
        let url = reachFiveApi.buildAuthorizeURL(queryParams: options)
        print(url)
        return url
    }
}
