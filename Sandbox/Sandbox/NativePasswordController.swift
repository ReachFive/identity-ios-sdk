import Foundation
import UIKit
import IdentitySdkCore
import BrightFutures

class NativePasswordController: UIViewController {
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBAction func passwordEditingDidEnd(_ sender: Any) {
        guard let pass = password.text, !pass.isEmpty, let user = username.text, !user.isEmpty else { return }
    
        let fut: Future<AuthToken, ReachFiveError>
        if (user.contains("@")) {
            fut = AppDelegate.reachfive().loginWithPassword(email: user, password: pass)
        } else {
            fut = AppDelegate.reachfive().loginWithPassword(phoneNumber: user, password: pass)
        }
        fut.onSuccess(callback: goToProfile)
            .onFailure { error in
                let alert = AppDelegate.createAlert(title: "Login", message: "Error: \(error.message())")
                self.present(alert, animated: true, completion: nil)
            }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let window = view.window else { fatalError("The view was not in the app's view hierarchy!") }
        
        AppDelegate.reachfive()
            .login(withRequest: NativeLoginRequest(anchor: window), usingModalAuthorizationFor: [.Password], display: .Always)
            .onSuccess(callback: goToProfile)
            .onFailure { error in
                switch error {
                case .AuthCanceled: return
                default:
                    let alert = AppDelegate.createAlert(title: "Login", message: "Error: \(error.message())")
                    self.present(alert, animated: true, completion: nil)
                }
            }
    }
}
