import UIKit
import IdentitySdkCore

class SignUpFidoControllerViewController: UIViewController {
    
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var givenNameText: UITextField!
    @IBOutlet weak var familyNameText: UITextField!
    @IBOutlet weak var deviceNameText: UITextField!
    let scopes = ["openid", "email", "profile", "phone", "full_write", "offline_access"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deviceNameText.text = UIDevice.current.name
    }
    
    @IBAction func SignupButton(_ sender: Any) {
        _ = ProfilePasskeySignupRequest(
            email: emailText.text,
            givenName: givenNameText.text,
            familyName: familyNameText.text)

/*
        AppDelegate.reachfive().signupWithWebAuthn(profile: profile,origin: AppDelegate.origin,friendlyName: deviceNameText.text,viewController: self,scopes: self.scopes)
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
}
