import Foundation
import UIKit
import IdentitySdkCore
import AuthenticationServices

class ActionController: UITableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let window = view.window else { fatalError("The view was not in the app's view hierarchy!") }
        
        let loginRequest = NativeLoginRequest(anchor: window)
        
        // Section Password
        if indexPath.section == 0 {
            if indexPath.row == 2 {
                AppDelegate.reachfive()
                    .webviewLogin(WebviewLoginRequest(state: "state", nonce: "nonce", scope: ["email", "profile"], presentationContextProvider: self))
                    .onComplete { self.handleResult(result: $0) }
            }
        }
        
        // Section Passkey
        if #available(iOS 16.0, *), indexPath.section == 2 {
            // Login with passkey: modal non-persistent
            if indexPath.row == 1 {
                AppDelegate.reachfive()
                    .login(withRequest: loginRequest, usingModalAuthorizationFor: [.Passkey], display: .IfImmediatelyAvailableCredentials)
                    .onSuccess(callback: goToProfile)
            } else
            // Login with passkey: modal persistent
            if indexPath.row == 2 {
                AppDelegate.reachfive()
                    .login(withRequest: loginRequest, usingModalAuthorizationFor: [.Passkey], display: .Always)
                    .onSuccess(callback: goToProfile)
            }
        }
        
        // Section Others
        if indexPath.section == 3 {
            // Login with refresh
            if indexPath.row == 2 {
                guard let token: AuthToken = AppDelegate.storage.get(key: SecureStorage.authKey) else {
                    return
                }
                AppDelegate.reachfive()
                    .refreshAccessToken(authToken: token)
                    .onSuccess(callback: goToProfile)
                    .onFailure { error in
                        print("refresh error \(error)")
                        AppDelegate.storage.clear(key: SecureStorage.authKey)
                    }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // passkey section restricted to iOS >= 16
        //TODO voir si on peut à la place carrément ne pas afficher la section
        if indexPath.section == 2, #unavailable(iOS 16.0) {
            let alert = AppDelegate.createAlert(title: "Login", message: "Passkey requires iOS 16")
            present(alert, animated: true, completion: nil)
            return nil
        }
        return indexPath
    }
    
    func handleResult(result: Result<AuthToken, ReachFiveError>) {
        switch result {
        case .success(let authToken):
            goToProfile(authToken)
        case .failure(let error):
            let alert = AppDelegate.createAlert(title: "Login failed", message: "Error: \(error.message())")
            present(alert, animated: true, completion: nil)
        }
    }
}

extension ActionController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        view.window!
    }
}
