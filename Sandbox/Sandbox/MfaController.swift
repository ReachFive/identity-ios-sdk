import Foundation
import UIKit
import IdentitySdkCore

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
    
    func mfaStart(registering credential: Credential, authToken: AuthToken) {
        mfaStart(registering: credential, authToken: authToken, retryIfStale: true)
    }
    
    private func mfaStart(registering credential: Credential, authToken: AuthToken, retryIfStale: Bool) {
        print("MfaController.startMfaPhoneRegistration")
        AppDelegate.reachfive()
            .mfaStart(registering: credential, authToken: authToken)
            .onSuccess { resp in
                self.handleStartVerificationCode(resp)
            }
            .onFailure { error in
                if retryIfStale, case let .AuthFailure(reason: _, apiError: apiError) = error,
                   let key = apiError?.errorMessageKey,
                   key == "error.accessToken.freshness" {
                    AppDelegate.reachfive()
                        .refreshAccessToken(authToken: authToken).onSuccess { (freshToken: AuthToken) in
                            AppDelegate.storage.setToken(freshToken)
                            self.mfaStart(registering: credential, authToken: freshToken, retryIfStale: false)
                        }
                        .onFailure { error in
                            self.mfaStart(presentFailure: credential, withError: error)
                        }
                }
                self.mfaStart(presentFailure: credential, withError: error)
            }
    }
    
    private func mfaStart(presentFailure credential: Credential, withError error: ReachFiveError) {
        let alert = AppDelegate.createAlert(title: "Start MFA \(credential.credentialType) Registration", message: "Error: \(error.message())")
        self.presentationAnchor.present(alert, animated: true)
    }
    
    private func handleStartVerificationCode(_ resp: MfaStartRegistrationResponse) {
        var alert: UIAlertController
        switch resp {
        case let .Success(registeredCredential):
            alert = AppDelegate.createAlert(title: "MFA \(registeredCredential.type) \(registeredCredential.friendlyName) enabled", message: "Success")
        
        case let .VerificationNeeded(continueRegistration):
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
                continueRegistration.verify(code: verificationCode)
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
        }
        presentationAnchor.present(alert, animated: true)
    }
}
