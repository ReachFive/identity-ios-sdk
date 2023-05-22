import UIKit
import Foundation
import IdentitySdkCore
import BrightFutures

class LoginWKWebviewController: UIViewController {
    
    @IBOutlet weak var loginWebview: LoginWKWebview!
    
    override func viewWillAppear(_ animated: Bool) {
        print("LoginWKWebviewController.viewWillAppear")
        super.viewWillAppear(animated)
        let promise = Promise<AuthToken, ReachFiveError>()
        loginWebview.loadLoginWebview(reachfive: AppDelegate.reachfive(), promise: promise)
        promise.future.onComplete { self.handleResult(result: $0) }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("LoginWKWebviewController.viewDidLoad")
    }
    
    // same as login with providers
    // used because when we do onFailure, we get a Swift.Error instead of a ReachFiveError
    func handleResult(result: Result<AuthToken, ReachFiveError>) {
        switch result {
        case .success(let authToken):
            AppDelegate.storage.save(key: AppDelegate.authKey, value: authToken)
            goToProfile()
        case .failure(let error):
            let alert = AppDelegate.createAlert(title: "Login failed", message: "Error: \(error)")
            present(alert, animated: true, completion: nil)
        }
    }
    
    // same as login with providers
    func goToProfile() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let profileController = storyBoard.instantiateViewController(withIdentifier: "ProfileScene")
        navigationController?.pushViewController(profileController, animated: true)
    }
}
