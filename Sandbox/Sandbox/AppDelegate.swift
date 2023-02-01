import UIKit
import IdentitySdkCore
import IdentitySdkFacebook
import IdentitySdkWebView
import IdentitySdkGoogle

//TODO
// Mettre une quatrième tabs:
// - Paramétrage : scopes, origin, utilisation du refresh au démarage ?
// Voir pour utiliser les scènes : 1 par que c'est plus moderne, deux par qu'il faut peut-être adapter certaines interface pour les app clients qui utilisent les scènes
// cf. wireframe de JC pour d'autres idées : https://miro.com/app/board/uXjVOMB0pG4=/
// Tester le MFA avec "Securing Logins with iCloud Keychain Verification Codes" https://developer.apple.com/documentation/authenticationservices/securing_logins_with_icloud_keychain_verification_codes
// Apparemment les custom scheme sont dépréciés et il faudrait utiliser les "Universal Links" : https://developer.apple.com/ios/universal-links/
// Apparemment il faut faire du dev pour partager des credentials entre Safari et une app (app-site association ne suffit pas) : https://developer.apple.com/documentation/security/shared_web_credentials
// Essayer de mettre tous les config du SDK dans le code et en choisir une avec Xcode Custom Environment Variables : https://derrickho328.medium.com/xcode-custom-environment-variables-681b5b8674ec
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    public static let storage = SecureStorage()
    
    let reachfive: ReachFive = ReachFive(
        sdkConfig: SdkConfig(
            domain: ProcessInfo.processInfo.environment["DOMAIN"]!,
            clientId: ProcessInfo.processInfo.environment["CLIENT_ID"]!,
            scheme: ProcessInfo.processInfo.environment["SCHEME"]!
        ),
        providersCreators: [
            // we can add back Facebook when we migrate to Swift Package Manager, or try this crazy fix : https://betterprogramming.pub/macos-catalyst-debugging-problems-using-catalyst-and-cocoapods-579679150fa9
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
        UIApplication.shared.delegate as! AppDelegate
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
        
        return reachfive.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        reachfive.application(app, open: url, options: options)
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

extension UIViewController {
    
    func goToProfile(_ authToken: AuthToken) {
        AppDelegate.storage.save(key: SecureStorage.authKey, value: authToken)
        
        if let tabBarController = storyboard?.instantiateViewController(withIdentifier: "Tabs") as? UITabBarController {
            tabBarController.selectedIndex = 2 // profile is third from left
            navigationController?.pushViewController(tabBarController, animated: true)
        }
    }
}

