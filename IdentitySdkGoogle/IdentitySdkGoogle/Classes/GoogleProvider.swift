import Foundation
import UIKit
import IdentitySdkCore
import GoogleSignIn
import BrightFutures

public class GoogleProvider: ProviderCreator {
    public static var NAME: String = "google"
    
    public var name: String = NAME
    
    public init() {}
    
    public func create(
        sdkConfig: SdkConfig,
        providerConfig: ProviderConfig,
        reachFiveApi: ReachFiveApi,
        clientConfigResponse: ClientConfigResponse
    ) -> Provider {
        ConfiguredGoogleProvider(
            sdkConfig: sdkConfig,
            providerConfig: providerConfig,
            reachFiveApi: reachFiveApi,
            clientConfigResponse: clientConfigResponse
        )
    }
}

public class ConfiguredGoogleProvider: NSObject, Provider {
    public var name: String = GoogleProvider.NAME
    
    var sdkConfig: SdkConfig
    var providerConfig: ProviderConfig
    var reachFiveApi: ReachFiveApi
    var clientConfigResponse: ClientConfigResponse
    
    public init(sdkConfig: SdkConfig, providerConfig: ProviderConfig, reachFiveApi: ReachFiveApi, clientConfigResponse: ClientConfigResponse) {
        self.sdkConfig = sdkConfig
        self.providerConfig = providerConfig
        self.reachFiveApi = reachFiveApi
        self.clientConfigResponse = clientConfigResponse
    }
    
    public func login(
        scope: [String]?,
        origin: String,
        viewController: UIViewController?
    ) -> Future<AuthToken, ReachFiveError> {
        let promise = Promise<AuthToken, ReachFiveError>()
        guard let viewController else {
            promise.failure(.TechnicalError(reason: "No presenting viewController"))
            return promise.future
        }
        
        let configuration = GIDConfiguration(clientID: providerConfig.clientId!)
        GIDSignIn.sharedInstance.signIn(with: configuration, presenting: viewController, hint: nil, additionalScopes: providerConfig.scope) { user, error in
            guard let user else {
                let reason = error == nil ? "No user" : error!.localizedDescription
                promise.failure(.AuthFailure(reason: reason))
                return
            }
            
            let loginProviderRequest = LoginProviderRequest(
                provider: self.providerConfig.provider,
                providerToken: user.authentication.accessToken,
                code: nil,
                origin: origin,
                clientId: self.sdkConfig.clientId,
                responseType: "token",
                scope: scope != nil ? scope!.joined(separator: " ") : self.clientConfigResponse.scope
            )
            promise.completeWith(
                self.reachFiveApi
                    .loginWithProvider(loginProviderRequest: loginProviderRequest)
                    .flatMap({ AuthToken.fromOpenIdTokenResponseFuture($0) })
            )
        }
        return promise.future
    }
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
    
    public func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        var _: [String: AnyObject] = [
            UIApplication.OpenURLOptionsKey.sourceApplication.rawValue: sourceApplication as AnyObject,
            UIApplication.OpenURLOptionsKey.annotation.rawValue: annotation as AnyObject
        ]
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        true
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {}
    
    public func logout() -> Future<(), ReachFiveError> {
        GIDSignIn.sharedInstance.signOut()
        return Future(value: ())
    }
    
    public override var description: String {
        "Provider: \(name)"
    }
}
