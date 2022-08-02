import UIKit
import IdentitySdkCore

class UpdatePhoneNumberController: UIViewController {
    let authToken: AuthToken? = AppDelegate.storage.get(key: AppDelegate.authKey)
    
    @IBOutlet weak var phoneNumberInput: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func update(_ sender: Any) {
        AppDelegate.reachfive()
            .updatePhoneNumber(authToken: authToken!, phoneNumber: phoneNumberInput.text ?? "")
            .onSuccess { profile in
                let alert = AppDelegate.createAlert(title: "Update", message: "Update Success")
                self.present(alert, animated: true, completion: nil)
            }
            .onFailure { error in
                let alert = AppDelegate.createAlert(title: "Update", message: "Update Error: \(error.localizedDescription)")
                self.present(alert, animated: true, completion: nil)
            }
    }
}
