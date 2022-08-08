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
    
    private func loginCallback(tkn: String, scopes: [String]?) -> Future<AuthToken, ReachFiveError> {
        let pkce = Pkce.generate()
        let scope = (scopes ?? scope).joined(separator: " ")
        let options = [
            "client_id": sdkConfig.clientId,
            "tkn": tkn,
            "response_type": codeResponseType,
            "redirect_uri": sdkConfig.scheme,
            "scope": scope,
            "code_challenge": pkce.codeChallenge,
            "code_challenge_method": pkce.codeChallengeMethod
        ]
        let authURL = reachFiveApi.buildAuthorizeURL(queryParams: options)
        return reachFiveApi.loginCallback(url: authURL).flatMap({ self.authWithCode(code: $0, pkce: pkce) })
    }
    
    internal func authWithCode(code: String, pkce: Pkce) -> Future<AuthToken, ReachFiveError> {
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
}
