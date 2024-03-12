import Foundation
import UIKit
import IdentitySdkCore
import BrightFutures

class MfaController: UIViewController {
    var authToken: AuthToken?
    
    var clearTokenObserver: NSObjectProtocol?
    var setTokenObserver: NSObjectProtocol?
    
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
        mfaStart(registering: credential, authToken: authToken, retryIfStaleToken: true)
    }
    
    private func mfaStart(registering credential: Credential, authToken: AuthToken, retryIfStaleToken: Bool) -> Future<(), ReachFiveError> {
        print("MfaController.startMfaPhoneRegistration")
        let future = AppDelegate.reachfive()
            .mfaStart(registering: credential, authToken: authToken)
            .recoverWith { error in
                guard retryIfStaleToken,
                      case let .AuthFailure(reason: _, apiError: apiError) = error,
                      let key = apiError?.errorMessageKey,
                      key == "error.accessToken.freshness"
                else {
                    return Future(error: error)
                }
                
                return AppDelegate.reachfive()
                    .refreshAccessToken(authToken: authToken).flatMap { (freshToken: AuthToken) in
                        AppDelegate.storage.setToken(freshToken)
                        return self.mfaStart(registering: credential, authToken: freshToken, retryIfStaleToken: false)
                    }
            }
        future
            .onSuccess { resp in
                self.handleStartVerificationCode(resp)
            }
            .onFailure { error in
                self.mfaStart(presentFailure: credential, withError: error)
            }
        
        return future
    }
    
    private func mfaStart(presentFailure credential: Credential, withError error: ReachFiveError) {
        let alert = AppDelegate.createAlert(title: "Start MFA \(credential.credentialType) Registration", message: "Error: \(error.message())")
        self.presentationAnchor.present(alert, animated: true)
    }
    
    private func handleStartVerificationCode(_ resp: MfaStartRegistrationResponse) -> Future<(), ReachFiveError> {
        switch resp {
        case let .Success(registeredCredential):
            let alert = AppDelegate.createAlert(title: "MFA \(registeredCredential.type) \(registeredCredential.friendlyName) enabled", message: "Success")
            presentationAnchor.present(alert, animated: true)
            return Future(value: ())
        
        case let .VerificationNeeded(continueRegistration):
            var promise: Promise<(), ReachFiveError>
            let canal =
            switch continueRegistration.credentialType {
            case .Email: "Email"
            case .PhoneNumber: "SMS"
            }
            
            alert = UIAlertController(title: "Verification Code", message: "Please enter the verification Code you got by \(canal)", preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = "Verification code"
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            let submitVerificationCode = UIAlertAction(title: "Submit", style: .default) { _ in
                guard let verificationCode = alert.textFields?[0].text else {
                    //TODO alerte
                    print("verification code cannot be empty")
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
            return promise.future
        }
    }
}
