import UIKit
import IdentitySdkCore
import IdentitySdkFacebook
import IdentitySdkWebView
import IdentitySdkGoogle

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    public static let storage = SecureStorage()
    public static let authKey = "AUTH_TOKEN"
    public static let origin = ProcessInfo.processInfo.environment["ORIGIN"]!


    let reachfive: ReachFive = ReachFive(
            sdkConfig: SdkConfig(
                    domain: ProcessInfo.processInfo.environment["DOMAIN"]!,
                    clientId: ProcessInfo.processInfo.environment["CLIENT_ID"]!,
                    scheme: ProcessInfo.processInfo.environment["SCHEME"]!
            ),
            providersCreators: [
                FacebookProvider(),
                GoogleProvider(),
                WebViewProvider()
            ],
            storage: UserDefaultsStorage()
    )

    static func reachfive() -> ReachFive {
        let app = UIApplication.shared.delegate as! AppDelegate
        return app.reachfive
    }

    static func shared() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    static func createAlert(title: String, message: String) -> UIAlertController {
        let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: UIAlertController.Style.alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        return alert
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("application:didFinishLaunchingWithOptions")
        reachfive.addPasswordlessCallback { result in
            print("addPasswordlessCallback \(result)")
        }

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return reachfive.application(app, open: url, options: options)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("applicationWillResignActive")
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("applicationDidEnterBackground")
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("applicationWillEnterForeground")
        guard let token: AuthToken = AppDelegate.storage.get(key: AppDelegate.authKey) else {
            // re-authenticate the user
            return
        }
        AppDelegate.reachfive()
                .refreshAccessToken(authToken: token)
                .onSuccess { refreshedAuthToken in
                    print("refresh successful")
                    AppDelegate.storage.save(key: AppDelegate.authKey, value: refreshedAuthToken)
                }
                .onFailure { error in
                    print("refresh error \(error)")
                    AppDelegate.storage.clear(key: AppDelegate.authKey)
                }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("applicationDidBecomeActive")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        reachfive.applicationDidBecomeActive(application)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("applicationWillTerminate")
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func applicationDidFinishLaunching(_ application: UIApplication) {
        print("applicationDidFinishLaunching")
    }

    func applicationProtectedDataWillBecomeUnavailable(_ application: UIApplication) {
        print("applicationProtectedDataWillBecomeUnavailable")
    }

    func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication) {
        print("applicationProtectedDataDidBecomeAvailable")
    }
}
