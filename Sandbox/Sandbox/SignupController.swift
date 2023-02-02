import UIKit
import IdentitySdkCore

class SignupController: UIViewController {
    var initialEmail: String?
    
    @IBOutlet weak var emailInput: UITextField!
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var nameInput: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailInput.text = initialEmail
    }
    
    @IBAction func signup(_ sender: Any) {
        let email = emailInput.text ?? ""
        let password = passwordInput.text ?? ""
        let name = nameInput.text ?? ""
        
        let profile = ProfileSignupRequest(
            password: password,
            email: email,
            name: name
        )
        AppDelegate.reachfive().signup(profile: profile)
            .onSuccess(callback: goToProfile)
            .onFailure { error in
                let alert = AppDelegate.createAlert(title: "Signup", message: "Error: \(error.message())")
                self.present(alert, animated: true, completion: nil)
            }
    }
}
