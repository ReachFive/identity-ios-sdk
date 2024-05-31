import Foundation
import UIKit
import IdentitySdkCore
import AuthenticationServices

class ActionController: UITableViewController {
    
    override func viewDidLoad() {
        AppDelegate.reachfive().addAccountRecoveryCallback { result in
            print("addAccountRecoveryCallback \(result)")
            switch result {
            case .success(let resp):
                guard let window = self.view.window else { fatalError("The view was not in the app's view hierarchy!") }
                if #available(macCatalyst 16.0, *) {
                    AppDelegate.reachfive().resetPasskeys(withRequest: ResetPasskeyRequest(verificationCode: resp.verificationCode, friendlyName: resp.email, anchor: window, email: resp.email))
                        .onSuccess { () in
                            print("succcess reset")
                        }
                        .onFailure { error in
                            print("Error: \(error.message())")
                        }
                }
            case .failure(let error):
                let alert = AppDelegate.createAlert(title: "Account Recovery Failed", message: "Error: \(error.message())")
                self.present(alert, animated: true)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let window = view.window else { fatalError("The view was not in the app's view hierarchy!") }
        
        let loginRequest = NativeLoginRequest(anchor: window, origin: "ActionController: Section Passkey")
        
        // Section Passkey
        if #available(iOS 16.0, *), indexPath.section == 2 {
            // Login with passkey: modal persistent
            if indexPath.row == 1 {
                AppDelegate.reachfive()
                    .login(withRequest: loginRequest, usingModalAuthorizationFor: [.Passkey], display: .Always)
                    .onSuccess(callback: goToProfile)
            } else
            // Login with passkey: modal non-persistent
            if indexPath.row == 2 {
                AppDelegate.reachfive()
                    .login(withRequest: loginRequest, usingModalAuthorizationFor: [.Passkey], display: .IfImmediatelyAvailableCredentials)
                    .onSuccess(callback: goToProfile)
            }
        }
        
        // Section Webview
        if indexPath.section == 3 {
            // standard webview
            if indexPath.row == 0 {
                AppDelegate.reachfive()
                    .webviewLogin(WebviewLoginRequest(state: "state", nonce: "nonce", scope: ["email", "profile"], presentationContextProvider: self, origin: "ActionController.webviewLogin"))
                    .onComplete { self.handleResult(result: $0) }
            }
        }
        
        // Section Others
        if indexPath.section == 4 {
            // Login with refresh
            if indexPath.row == 2 {
                guard let token = AppDelegate.storage.getToken() else {
                    return
                }
                AppDelegate.reachfive()
                    .refreshAccessToken(authToken: token)
                    .onSuccess(callback: goToProfile)
                    .onFailure { error in
                        print("refresh error \(error)")
                        AppDelegate.storage.removeToken()
                    }
            }
        }
        
        // Section Recovery
        if indexPath.section == 5 {
            // Login with refresh
            if indexPath.row == 1 {
                let alert = UIAlertController(title: "Recover account", message: "Enter your identifier", preferredStyle: .alert)
                alert.addTextField()
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                let sendAction = UIAlertAction(title: "Send recovery link", style: .default) { [unowned alert] (_) in
                    let textField = alert.textFields?[0]
                    AppDelegate.reachfive().requestAccountRecovery(email: textField?.text)
                        .onSuccess { () in
                            self.showToast(message: "Email Sent", seconds: 1)
                        }
                        .onFailure { error in
                            let alert = AppDelegate.createAlert(title: "Login failed", message: "Error: \(error.message())")
                            self.present(alert, animated: true)
                        }
                }
                alert.addAction(sendAction)
                alert.preferredAction = sendAction
                self.present(alert, animated: true)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // passkey section restricted to iOS >= 16
        //TODO voir si on peut à la place carrément ne pas afficher la section
        if indexPath.section == 2, #unavailable(iOS 16.0) {
            let alert = AppDelegate.createAlert(title: "Login", message: "Passkey requires iOS 16")
            present(alert, animated: true)
            return nil
        }
        #if targetEnvironment(macCatalyst)
        if indexPath.section == 2, indexPath.row == 3 {
            let alert = AppDelegate.createAlert(title: "Login", message: "AutoFill not available on macOS")
            present(alert, animated: true)
            return nil
        }
        #endif
        return indexPath
    }
    
    func handleResult(result: Result<AuthToken, ReachFiveError>) {
        switch result {
        case .success(let authToken):
            goToProfile(authToken)
        case .failure(let error):
            let alert = AppDelegate.createAlert(title: "Login failed", message: "Error: \(error.message())")
            present(alert, animated: true)
        }
    }
}

extension ActionController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        view.window!
    }
}
