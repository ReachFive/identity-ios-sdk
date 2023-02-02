import UIKit
import IdentitySdkCore

class LoginWithFidoViewController: UIViewController {
    
    @IBOutlet weak var emailText: UITextField!
    let scopes = ["openid", "email", "profile", "phone", "full_write", "offline_access"]
    
    @IBAction func loginButton(_ sender: Any) {

/*
        AppDelegate.reachfive().loginWithWebAuthn(email: self.emailText.text!,origin: AppDelegate.origin,scopes: scopes,viewController: self)
        { (authToken) -> Any in
            authToken.onSuccess(callback: self.goToProfile)
                .onFailure { error in
                    var messageAlert = ""
                    switch error {
                    case .RequestError(let requestErrors):
                        messageAlert = requestErrors.errorDescription!
                    case .TechnicalError(_, let apiError):
                        messageAlert = (apiError?.errorDescription)! as String
                    default:
                        messageAlert = error.localizedDescription
                    }
                    let alert = UIAlertController(title: "Error", message:messageAlert, preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
        }
    */
    }
}
