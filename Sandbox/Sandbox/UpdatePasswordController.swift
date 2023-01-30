import UIKit
import Foundation
import IdentitySdkCore

class UpdatePasswordController: UIViewController {
    var authToken: AuthToken? = AppDelegate.storage.get(key: AppDelegate.authKey)
    @IBOutlet weak var oldPassword: UITextField!
    @IBOutlet weak var newPassword: UITextField!
    
    @IBAction func update(_ sender: Any) {
        if authToken != nil {
            AppDelegate.reachfive()
                .updatePassword(.AccessTokenParams(authToken: authToken!, password: newPassword.text ?? "", oldPassword: oldPassword.text ?? ""))
                .onSuccess {
                    let alert = AppDelegate.createAlert(title: "Update Password", message: "Success")
                    self.present(alert, animated: true, completion: nil)
                }
                .onFailure { error in
                    let alert = AppDelegate.createAlert(title: "Update Password", message: "Error: \(error.message())")
                    self.present(alert, animated: true, completion: nil)
                }
        }
    }
}
