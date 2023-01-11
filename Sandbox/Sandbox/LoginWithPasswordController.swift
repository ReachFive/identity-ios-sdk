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
        AppDelegate.reachfive()
            .loginWithPassword(email: email, phoneNumber: phoneNumber, customIdentifier: customIdentifier, password: password)
            .onSuccess(callback: goToProfile)
            .onFailure { error in
                self.error.text = error.message()
            }
    }
    
    func goToProfile(_ authToken: AuthToken) {
        AppDelegate.storage.save(key: AppDelegate.authKey, value: authToken)
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let profileController = storyBoard.instantiateViewController(
            withIdentifier: "ProfileScene"
        ) as! ProfileController
        error.text = nil
        navigationController?.pushViewController(profileController, animated: true)
    }
}
