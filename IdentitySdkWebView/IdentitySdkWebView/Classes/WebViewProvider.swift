import Foundation
import SafariServices
import IdentitySdkCore
import BrightFutures

public class WebViewProvider: ProviderCreator {
    public static let NAME = "webview"
    
    public var name: String = NAME
    
    public init() {}
    
    public func create(
        sdkConfig: SdkConfig,
        providerConfig: ProviderConfig,
        reachFiveApi: ReachFiveApi,
        clientConfigResponse: ClientConfigResponse
    ) -> Provider {
        return ConfiguredWebViewProvider(
            sdkConfig: sdkConfig,
            providerConfig: providerConfig,
            reachFiveApi: reachFiveApi,
            clientConfigResponse: clientConfigResponse
        )
    }
}

class ConfiguredWebViewProvider: NSObject, Provider, SFSafariViewControllerDelegate {
    private let notificationName = Notification.Name("AuthCallbackNotification")
    private var safariViewController: SFSafariViewController? = nil
    private var pkce: Pkce = Pkce.generate()
    private var promise: Promise<AuthToken, ReachFiveError>?
    
    var name: String = WebViewProvider.NAME
    
    let sdkConfig: SdkConfig
    let providerConfig: ProviderConfig
    let reachFiveApi: ReachFiveApi
    let clientConfigResponse: ClientConfigResponse
    
    public init(
        sdkConfig: SdkConfig,
        providerConfig: ProviderConfig,
        reachFiveApi: ReachFiveApi,
        clientConfigResponse: ClientConfigResponse
    ) {
        self.sdkConfig = sdkConfig
        self.providerConfig = providerConfig
        self.reachFiveApi = reachFiveApi
        self.name = providerConfig.provider
        self.clientConfigResponse = clientConfigResponse
    }
    
    public func login(
        scope: [String]?,
        origin: String,
        viewController: UIViewController?
    ) -> Future<AuthToken, ReachFiveError> {
        self.promise?.tryFailure(.AuthCanceled)
        let promise = Promise<AuthToken, ReachFiveError>()
        self.promise = promise
        self.pkce = Pkce.generate()
        UserDefaultsStorage().save(key: "PASSWORDLESS_PKCE", value: pkce)
        let url = self.buildUrl(
            sdkConfig: sdkConfig,
            providerConfig: providerConfig,
            scope: scope != nil ? scope!.joined(separator: " ") : self.clientConfigResponse.scope,
            pkce: pkce
        )
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleLogin(_:)), name: self.notificationName, object: nil)
        
        self.safariViewController = SFSafariViewController.init(url: URL(string: url)!)
        
        viewController?.present(safariViewController!, animated: true)
        return promise.future
    }
    
    @objc func handleLogin(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self, name: self.notificationName, object: nil)
        
        let url = notification.object as? URL
        
        if let query = url?.query {
            let params = QueryString.parseQueriesStrings(query: query)
            let code = params["code"]
            if code != nil {
                self.handleAuthCode(code!!)
            } else {
                self.promise?.failure(.TechnicalError(reason: "No authorization code"))
            }
        } else {
            self.promise?.failure(.TechnicalError(reason: "No authorization code"))
        }
        
        self.safariViewController?.dismiss(animated: true, completion: nil)
    }
    
    private func handleAuthCode(_ code: String) {
        let authCodeRequest = AuthCodeRequest(
            clientId: self.sdkConfig.clientId,
            code: code,
            redirectUri: sdkConfig.scheme,
            pkce: self.pkce
        )
        self.reachFiveApi.authWithCode(authCodeRequest: authCodeRequest)
            .flatMap({ AuthToken.fromOpenIdTokenResponseFuture($0) })
            .onSuccess { authToken in
                self.promise?.success(authToken)
            }
            .onFailure { error in
                self.promise?.failure(error)
            }
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        NotificationCenter.default.removeObserver(self, name: self.notificationName, object: nil)
        controller.dismiss(animated: true, completion: nil)
    }
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        if let sourceApplication = options[.sourceApplication] {
            if (String(describing: sourceApplication) == "com.apple.SafariViewService") {
                NotificationCenter.default.post(name: self.notificationName, object: url)
                return true
            }
        }
        
        return false
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return true
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        
    }
    
    public func logout() -> Future<(), ReachFiveError> {
        return Future.init(value: ())
    }
    
    func buildUrl(sdkConfig: SdkConfig, providerConfig: ProviderConfig, scope: String, pkce: Pkce) -> String {
        let params = [
            "provider": providerConfig.provider,
            "client_id": sdkConfig.clientId,
            "response_type": "code",
            "redirect_uri": sdkConfig.scheme,
            "scope": scope,
            "platform": "ios",
            "code_challenge": pkce.codeChallenge,
            "code_challenge_method": pkce.codeChallengeMethod,
        ]
        let queryStrings = params
            .map { "\($0)=\($1)" }
            .map { $0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) }
            .filter { $0 != nil }
            .map { $0! }
            .joined(separator: "&")
        return "https://\(sdkConfig.domain)/oauth/authorize?\(queryStrings)"
    }
    
    override var description: String {
        return "Provider: \(self.name)"
    }
}
