import Foundation
import UIKit
import IdentitySdkCore

class MfaController: UIViewController, ProfileRootController {
    var authToken: AuthToken?
    
    var clearTokenObserver: NSObjectProtocol?
    var setTokenObserver: NSObjectProtocol?
    
    var rootController: UIViewController? {
        return self
    }
    
    
    @IBOutlet weak var phoneNumberMfaRegistration: UITextField!
    @IBOutlet weak var phoneMfaRegistrationCode: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clearTokenObserver = NotificationCenter.default.addObserver(forName: .DidClearAuthToken, object: nil, queue: nil) { _ in
            self.didLogout()
        }
        
        setTokenObserver = NotificationCenter.default.addObserver(forName: .DidSetAuthToken, object: nil, queue: nil) { _ in
            self.didLogin()
        }
        authToken = AppDelegate.storage.get(key: SecureStorage.authKey)
    }
    
    func didLogin() {
        authToken = AppDelegate.storage.get(key: SecureStorage.authKey)
    }
    
    func didLogout() {
        authToken = nil
        phoneNumberMfaRegistration.text = nil
        phoneMfaRegistrationCode.text = nil
    }
  
    @IBAction func startMfaPhoneRegistration(_ sender: UIButton) {
        print("MfaController.startMfaPhoneRegistration")
        guard let authToken else {
            print("not logged in")
            return
        }
        let phoneNumber = phoneNumberMfaRegistration.text
        guard let phoneNumber else {
            print("phone number cannot be empty")
            return
        }
        
        doMfaPhoneRegistration(phoneNumber: phoneNumber, authToken: authToken)
    }
}



 extension ProfileRootController {
    func doMfaPhoneRegistration(phoneNumber: String, authToken: AuthToken) {
            print("MfaController.startMfaPhoneRegistration")
            AppDelegate.reachfive()
                .mfaStart(registering: .PhoneNumber(phoneNumber), authToken: authToken)
                .onSuccess { resp in
                    self.handleStartVerificationCode(resp, authToken: authToken)
                }
                .onFailure { error in
                    let alert = AppDelegate.createAlert(title: "Start MFA phone Registration", message: "Error: \(error.message())")
                    rootController?.present(alert, animated: true, completion: nil)
                }
        }
    
        
    func doMfaEmailRegistration(authToken: AuthToken) {
            print("MfaController.startEmailMfaRegistering")
            AppDelegate.reachfive()
                .mfaStart(registering: .Email(), authToken: authToken)
                .onSuccess { resp in
                    self.handleStartVerificationCode(resp, authToken: authToken)
                }
                .onFailure { error in
                    let alert = AppDelegate.createAlert(title: "Start MFA email Registration", message: "Error: \(error.message())")
                    rootController?.present(alert, animated: true, completion: nil)
                }
        }
        
    private func handleStartVerificationCode(_ resp: MfaStartRegistrationResponse, authToken: AuthToken) {
        var alertController: UIAlertController
        switch resp {
        case let .Success(registeredCredential):
            alertController = AppDelegate.createAlert(title: "MFA \(registeredCredential.type) \(registeredCredential.friendlyName) enabled", message: "Success")

        case let .VerificationNeeded(continueRegistration):
            let canal = switch continueRegistration.credentialType {
            case .Email: "Email"
            case .PhoneNumber: "SMS"
            }

            alertController = UIAlertController(title: "Verification Code", message: "Please enter the verification Code you got by \(canal)", preferredStyle: .alert)
            alertController.addTextField { (textField) in
                textField.placeholder = "Verification code"
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

            let submitVerificationCode = UIAlertAction(title: "submit", style: .default) { _ in
                let verificationCode = alertController.textFields![0].text
                guard let verificationCode else {
                    print("verification code cannot be empty")
                    return
                }
                continueRegistration.verify(code: verificationCode, freshAuthToken: authToken)
                    .onSuccess { succ in
                        let alert = AppDelegate.createAlert(title: "Verify MFA \(continueRegistration.credentialType) registration", message: "Success")
                        rootController?.present(alert, animated: true)
                    }
                    .onFailure { error in
                        let toBeRegistered =
                        switch continueRegistration.credentialType {
                        case .PhoneNumber:
                            "phone number"
                        case .Email:
                            "email"
                        }
                        let alert = AppDelegate.createAlert(title: "MFA \(toBeRegistered) failure", message: "Error: \(error.message())")
                        rootController?.present(alert, animated: true)
                    }
            }
            alertController.addAction(cancelAction)
            alertController.addAction(submitVerificationCode)
        }
        rootController?.present(alertController, animated: true, completion: nil)
    }
}
