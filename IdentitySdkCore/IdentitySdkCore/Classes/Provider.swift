import Foundation
import UIKit
import BrightFutures

public protocol ProviderCreator {
    var name: String { get }
    func create(sdkConfig: SdkConfig, providerConfig: ProviderConfig, reachFiveApi: ReachFiveApi, clientConfigResponse: ClientConfigResponse) -> Provider
}

public protocol Provider {
    var name: String { get }
    func login(scope: [String]?, origin: String, viewController: UIViewController?) -> Future<AuthToken, ReachFiveError>
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    func applicationDidBecomeActive(_ application: UIApplication)
    func logout() -> Future<(), ReachFiveError>
}
