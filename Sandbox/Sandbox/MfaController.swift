import Foundation
import UIKit
import IdentitySdkCore
import BrightFutures

class MfaController: UIViewController {
    @IBOutlet weak var phoneNumberMfaRegistration: UITextField!
    
    @IBAction func startMfaPhoneRegistration(_ sender: UIButton) {
        print("MfaController.startMfaPhoneRegistration")
        guard let authToken = AppDelegate.storage.getToken() else {
            print("not logged in")
            return
        }
        guard let phoneNumber = phoneNumberMfaRegistration.text else {
            print("phone number cannot be empty")
            return
        }
        
        let mfaAction = MfaAction(presentationAnchor: self)
        mfaAction.mfaStart(registering: .PhoneNumber(phoneNumber), authToken: authToken)
    }
}

class MfaAction {
    let presentationAnchor: UIViewController
    
    public init(presentationAnchor: UIViewController) {
        self.presentationAnchor = presentationAnchor
    }
    
    func mfaStart(registering credential: Credential, authToken: AuthToken) -> Future<(), ReachFiveError> {
        let future = AppDelegate.reachfive()
            .mfaStart(registering: credential, authToken: authToken)
            .recoverWith { error in
                guard case let .AuthFailure(reason: _, apiError: apiError) = error,
                      let key = apiError?.errorMessageKey,
                      key == "error.accessToken.freshness"
                else {
                    return Future(error: error)
                }
                
                // Automatically refresh the token if it is stale
                return AppDelegate.reachfive()
                    .refreshAccessToken(authToken: authToken).flatMap { (freshToken: AuthToken) in
                        AppDelegate.storage.setToken(freshToken)
                        return AppDelegate.reachfive()
                            .mfaStart(registering: credential, authToken: freshToken)
                    }
            }
            .flatMap { resp in
                self.handleStartVerificationCode(resp)
            }
            .onFailure { error in
                let alert = AppDelegate.createAlert(title: "Start MFA \(credential.credentialType) Registration", message: "Error: \(error.message())")
                self.presentationAnchor.present(alert, animated: true)
            }
        
        return future
    }
    
    private func handleStartVerificationCode(_ resp: MfaStartRegistrationResponse) -> Future<(), ReachFiveError> {
        let promise: Promise<(), ReachFiveError> = Promise()
        switch resp {
        case let .Success(registeredCredential):
            let alert = AppDelegate.createAlert(title: "MFA \(registeredCredential.type) \(registeredCredential.friendlyName) enabled", message: "Success")
            presentationAnchor.present(alert, animated: true)
            promise.success(())
        
        case let .VerificationNeeded(continueRegistration):
            let canal =
            switch continueRegistration.credentialType {
            case .Email: "Email"
            case .PhoneNumber: "SMS"
            }
            
            let alert = UIAlertController(title: "Verification Code", message: "Please enter the verification Code you got by \(canal)", preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = "Verification code"
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                promise.failure(.AuthCanceled)
            }
            
            let submitVerificationCode = UIAlertAction(title: "Submit", style: .default) { _ in
                guard let verificationCode = alert.textFields?[0].text, !verificationCode.isEmpty else {
                    print("verification code cannot be empty")
                    promise.failure(.AuthFailure(reason: "no verification code"))
                    return
                }
                let future = continueRegistration.verify(code: verificationCode)
                promise.completeWith(future)
                future
                    .onSuccess { succ in
                        let alert = AppDelegate.createAlert(title: "Verify MFA \(continueRegistration.credentialType) registration", message: "Success")
                        self.presentationAnchor.present(alert, animated: true)
                    }
                    .onFailure { error in
                        let alert = AppDelegate.createAlert(title: "MFA \(continueRegistration.credentialType) failure", message: "Error: \(error.message())")
                        self.presentationAnchor.present(alert, animated: true)
                    }
            }
            alert.addAction(cancelAction)
            alert.addAction(submitVerificationCode)
            alert.preferredAction = submitVerificationCode
            presentationAnchor.present(alert, animated: true)
        }
        return promise.future
    }
}
