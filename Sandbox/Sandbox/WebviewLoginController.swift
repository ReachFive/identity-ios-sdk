import UIKit
import Foundation
import IdentitySdkCore
import AuthenticationServices

class WebviewLoginController: UIViewController, ASWebAuthenticationPresentationContextProviding {
    
    @IBAction func login(_ sender: Any) {
        AppDelegate.reachfive()
            .webviewLogin(WebviewLoginRequest(state: "state", nonce: "nonce", scope: ["email", "profile"], presentationContextProvider: self))
            .onComplete { self.handleResult(result: $0) }
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
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        view.window!
    }
}
