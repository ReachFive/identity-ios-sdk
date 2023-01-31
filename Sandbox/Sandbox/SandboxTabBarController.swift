import Foundation
import UIKit
import IdentitySdkCore

class SandboxTabBarController: UITabBarController {
    // I did not manage to regroup the management of the profile icon in one place
    // there are multiple ways to navigate betweeen the different views and they require different treatment
    // when the profile controller is pushed onto the stack of views programmatically
    // when the user touch the different tabs
    // when the app is relaunched directly in the profile tab...
    // also the notifications are not always available, especially in the profile controller, because the view is not yet loaded
    public static let profileCheck = UIImage(systemName: "person.crop.circle.badge.checkmark")
    public static let profileCheckFill = UIImage(systemName: "person.crop.circle.fill.badge.checkmark")
    public static let profileX = UIImage(systemName: "person.crop.circle.badge.xmark")
    public static let profileXFill = UIImage(systemName: "person.crop.circle.fill.badge.xmark")
    
    @IBOutlet weak var sandboxTabBar: UITabBar?
    
    var clearTokenObserver: NSObjectProtocol?
    var setTokenObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        print("SandboxTabBarController.viewDidLoad")
        super.viewDidLoad()
        
        clearTokenObserver = NotificationCenter.default.addObserver(forName: .DidClearAuthToken, object: nil, queue: nil) { _ in
            self.didLogout()
        }
        
        setTokenObserver = NotificationCenter.default.addObserver(forName: .DidSetAuthToken, object: nil, queue: nil) { _ in
            self.didLogin()
        }
        
        if #unavailable(iOS 16.0) {
            sandboxTabBar?.items?[0].image = UIImage(systemName: "list.bullet")
        }
        
        if let _: AuthToken = AppDelegate.storage.get(key: SecureStorage.authKey) {
            sandboxTabBar?.items?[2].image = SandboxTabBarController.profileCheck
            sandboxTabBar?.items?[2].selectedImage = SandboxTabBarController.profileCheckFill
        }
    }
    
    func didLogout() {
        print("SandboxTabBarController.didLogout")
        sandboxTabBar?.items?[2].image = SandboxTabBarController.profileX
        sandboxTabBar?.items?[2].selectedImage = SandboxTabBarController.profileXFill
    }
    
    func didLogin() {
        print("SandboxTabBarController.didLogin")
        sandboxTabBar?.items?[2].image = SandboxTabBarController.profileCheck
        sandboxTabBar?.items?[2].selectedImage = SandboxTabBarController.profileCheckFill
    }
}
