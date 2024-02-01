import Foundation
import UIKit
import IdentitySdkCore

class MfaCredentialsController: UIViewController {
    var authToken: AuthToken?
    
    var clearTokenObserver: NSObjectProtocol?
    var setTokenObserver: NSObjectProtocol?
    
    
    @IBOutlet weak var redirectUrl: UITextField!
    @IBOutlet weak var emailVerificationCode: UITextField!
    @IBOutlet weak var phoneNumberVerificationCode: UITextField!
    @IBOutlet weak var phoneNumberVerifyRegistration: UITextField!
    @IBOutlet weak var phoneNumberStartRegistration: UITextField!
    
    
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
        redirectUrl.text = nil
        phoneNumberStartRegistration.text = nil
        phoneNumberVerifyRegistration.text = nil
        phoneNumberVerificationCode.text = nil
        emailVerificationCode.text = nil
    }
    @IBAction func startMfaPhoneRegistration(_ sender: UIButton) {
        print("MfaCredentialsController.startMfaPhoneRegistration")
        guard let authToken else {
            print("not logged in")
            return
        }
        let phoneNumber = phoneNumberStartRegistration.text
        guard let phoneNumber else {
            print("phone number cannot be empty")
            return
        }
        AppDelegate.reachfive()
            .startMfaCredentialRegistration(authToken: authToken, request: StartMfaCredentialRegistrationRequest.PhoneNumber(phoneNumber: phoneNumber))
            .onSuccess {
                let alert = AppDelegate.createAlert(title: "Start MFA phone Registration", message: "Success")
                self.present(alert, animated: true, completion: nil)
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
        let verificationCode = phoneNumberVerificationCode.text
        guard let verificationCode else {
            print("verification code cannot be empty")
            return
        }
        let phoneNumber = phoneNumberVerifyRegistration.text
        guard let phoneNumber else {
            print("phone number verify cannot be empty")
            return
        }
        AppDelegate.reachfive()
            .verifyMfaCredentialRegistration(authToken: authToken, request: VerifyMfaCredentialRegistrationRequest.PhoneNumber(verificationCode: verificationCode, phoneNumber: phoneNumber))
            .onSuccess {
                let alert = AppDelegate.createAlert(title: "Verify MFA email Registration", message: "Success")
                self.present(alert, animated: true, completion: nil)
            }
            .onFailure { error in
                let alert = AppDelegate.createAlert(title: "Verify MFA email Registration", message: "Error: \(error.message())")
                self.present(alert, animated: true, completion: nil)
            }
    }
    
    @IBAction func verifyMfaEmailRegistration(_ sender: UIButton) {
        print("MfaCredentialsController.verifyMfaEmailRegistration")
        guard let authToken else {
            print("not logged in")
            return
        }
        let verificationCode = emailVerificationCode.text
        guard let verificationCode else {
            print("verification cannot be empty")
            return
        }
        AppDelegate.reachfive()
            .verifyMfaCredentialRegistration(authToken: authToken, request: VerifyMfaCredentialRegistrationRequest.Email(verificationCode: verificationCode))
            .onSuccess {
                let alert = AppDelegate.createAlert(title: "Verify MFA email Registration", message: "Success")
                self.present(alert, animated: true, completion: nil)
            }
            .onFailure { error in
                let alert = AppDelegate.createAlert(title: "Verify MFA email Registration", message: "Error: \(error.message())")
                self.present(alert, animated: true, completion: nil)
            }
        
    }
    @IBAction func startMfaEmailRegistration(_ sender: UIButton) {
        print("MfaCredentialsController.startMfaEmailRegistration")
        guard let authToken else {
            print("not logged in")
            return
        }
        AppDelegate.reachfive()
            .startMfaCredentialRegistration(
                authToken: authToken,
                request: StartMfaCredentialRegistrationRequest.Email(redirectUrl: redirectUrl.text)
            )
            .onSuccess {
                let alert = AppDelegate.createAlert(title: "Start MFA email Registration", message: "Success")
                self.present(alert, animated: true, completion: nil)
            }
            .onFailure { error in
                let alert = AppDelegate.createAlert(title: "Start MFA email Registration", message: "Error: \(error.message())")
                self.present(alert, animated: true, completion: nil)
            }
    }
}
