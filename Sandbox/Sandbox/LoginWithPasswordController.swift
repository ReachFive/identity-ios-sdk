import Foundation
import UIKit
import IdentitySdkCore

class LoginWithPasswordController: UIViewController {
    @IBOutlet weak var emailInput: UITextField!
    @IBOutlet weak var phoneNumberInput: UITextField!
    @IBOutlet weak var customIdentifierInput: UITextField!
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var error: UILabel!
    
    @IBAction func login(_ sender: Any) {
        let email = emailInput.text
        let phoneNumber = phoneNumberInput.text
        let customIdentifier = customIdentifierInput.text
        let password = passwordInput.text ?? ""
        guard let window = view.window else { fatalError("The view was not in the app's view hierarchy!") }
        
        AppDelegate.reachfive()
            .loginWithPassword(email: email, phoneNumber: phoneNumber, customIdentifier: customIdentifier, password: password)
            .onSuccess { token in
                self.error.text = nil
                self.goToProfile(token)
            }
            .onFailure { error in
                self.error.text = error.message()
            }
    }
}
