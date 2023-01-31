import UIKit
import IdentitySdkCore

class SignupPasskeyController: UIViewController {
    @IBOutlet weak var usernameInput: UITextField!
    @IBOutlet weak var nameInput: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func signup(_ sender: Any) {
        guard let name = nameInput.text else {
            print("No name provided")
            return
        }
        
        guard let username = usernameInput.text else {
            print("No username provided")
            return
        }
        let profile: ProfilePasskeySignupRequest
        if (username.contains("@")) {
            profile = ProfilePasskeySignupRequest(
                email: username,
                name: name
            )
        } else {
            profile = ProfilePasskeySignupRequest(
                phoneNumber: username,
                name: name
            )
        }
        
        if #available(iOS 16.0, *) {
            let window: UIWindow = view.window!
            AppDelegate.reachfive().signup(withRequest: PasskeySignupRequest(passkeyPofile: profile, friendlyName: username, anchor: window))
                .onSuccess(callback: goToProfile)
                .onFailure { error in
                    let alert = AppDelegate.createAlert(title: "Signup", message: "Error: \(error.message())")
                    self.present(alert, animated: true, completion: nil)
                }
        } else {
            let alert = AppDelegate.createAlert(title: "Signup", message: "Passkey requires iOS 16")
            present(alert, animated: true, completion: nil)
        }
    }
}
