import Foundation
import UIKit
import IdentitySdkCore

class LoginWithPasswordController: UIViewController {
    @IBOutlet weak var usernameInput: UITextField!
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var error: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AppDelegate.reachfive().initialize().onComplete { _ in
        }
    }
    
    @IBAction func login(_ sender: Any) {
        let email = usernameInput.text ?? ""
        let password = passwordInput.text ?? ""
        AppDelegate.reachfive()
            .loginWithPassword(username: email, password: password)
            .onSuccess(callback: goToProfile)
            .onFailure(callback: { error in
                switch error {
                case .RequestError(let requestErrors):
                    self.error.text = requestErrors.errorUserMsg
                default:
                    self.error.text = error.localizedDescription
                }
            })
    }
    
    func goToProfile(_ authToken: AuthToken) {
        AppDelegate.storage.save(key: AppDelegate.authKey, value: authToken)
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let profileController = storyBoard.instantiateViewController(
            withIdentifier: "ProfileScene"
        ) as! ProfileController
        navigationController?.pushViewController(profileController, animated: true)
    }
}
