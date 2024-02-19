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
        print("MfaCredentialsController.viewDidLoad")
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
        print("ProfileController.didLogin")
        authToken = AppDelegate.storage.get(key: SecureStorage.authKey)
    }
    
    func didLogout() {
        print("ProfileController.didLogout")
        authToken = nil
        phoneNumberMfaRegistration.text = nil
        phoneMfaRegistrationCode.text = nil
    }
  
    @IBAction func startMfaPhoneRegistration(_ sender: UIButton) {
        print("MfaCredentialsController.startMfaPhoneRegistration")
        guard let authToken else {
            print("not logged in")
            return
        }
        let phoneNumber = phoneNumberMfaRegistration.text
        guard let phoneNumber else {
            print("phone number cannot be empty")
            return
        }
        AppDelegate.reachfive()
            .mfaStartRegistering(credential: .PhoneNumber(phoneNumber), authToken: authToken)
            .onSuccess { result in
                if(result.status == Status.enabled.rawValue) {
                    self.present(AppDelegate.createAlert(title: "Phone number \(phoneNumber) added as MFA", message: "Success"), animated: true, completion: nil)
                }
                else {
                    self.present(AppDelegate.createAlert(title: "Start MFA phone Registration", message: "Success"), animated: true, completion: nil)
                }
            }
            .onFailure { error in
                let alert = AppDelegate.createAlert(title: "Start MFA phone Registration", message: "Error: \(error.message())")
                self.present(alert, animated: true, completion: nil)
            }
    }
    
    @IBAction func verifyMfaPhoneRegistration(_ sender: UIButton) {
        print("MfaCredentialsController.verifyMfaPhoneRegistration")
        guard let authToken else {
            print("not logged in")
            return
        }
        let verificationCode = phoneMfaRegistrationCode.text
        guard let verificationCode else {
            print("verification code cannot be empty")
            return
        }
        let phoneNumber = phoneNumberMfaRegistration.text
        guard let phoneNumber else {
            print("phone number verify cannot be empty")
            return
        }
        AppDelegate.reachfive()
            .mfaVerifyRegistering(credential: .SMS, verificationCode: verificationCode, authToken: authToken)
            .onSuccess {
                let alert = AppDelegate.createAlert(title: "Verify MFA Phone Registration", message: "Success")
                self.present(alert, animated: true, completion: nil)
            }
            .onFailure { error in
                let alert = AppDelegate.createAlert(title: "Verify MFA Phone Registration", message: "Error: \(error.message())")
                self.present(alert, animated: true, completion: nil)
            }
    }
}
