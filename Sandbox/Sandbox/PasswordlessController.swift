import Foundation
import UIKit
import IdentitySdkCore

class PasswordlessController: UIViewController {
    
    @IBOutlet weak var redirectUriInput: UITextField!
    @IBOutlet weak var emailInput: UITextField!
    @IBOutlet weak var phoneNumberInput: UITextField!
    @IBOutlet weak var verificationCodeInput: UITextField!
    
    @IBAction func loginWithEmail(_ sender: Any) {
        AppDelegate.reachfive()
            .startPasswordless(
                .Email(
                    email: emailInput.text ?? "",
                    redirectUri: redirectUriInput.text != "" ? redirectUriInput.text : nil
                )
            )
            .onSuccess {
                let alert = AppDelegate.createAlert(title: "Login with email", message: "Success")
                self.present(alert, animated: true, completion: nil)
            }
            .onFailure { error in
                let alert = AppDelegate.createAlert(title: "Login with email", message: "Error: \(error.localizedDescription)")
                self.present(alert, animated: true, completion: nil)
            }
            .onComplete { result in
                print("startPasswordless email \(result)")
            }
    }
    
    @IBAction func loginWithPhoneNumber(_ sender: Any) {
        AppDelegate.reachfive()
            .startPasswordless(
                .PhoneNumber(
                    phoneNumber: phoneNumberInput.text ?? "",
                    redirectUri: redirectUriInput.text != "" ? redirectUriInput.text : nil
                )
            )
            .onSuccess {
                let alert = AppDelegate.createAlert(title: "Login with phone number", message: "Success")
                self.present(alert, animated: true, completion: nil)
            }
            .onFailure { error in
                let alert = AppDelegate.createAlert(title: "Login with phone number", message: "Error: \(error.localizedDescription)")
                self.present(alert, animated: true, completion: nil)
            }
            .onComplete { result in
                print("startPasswordless phone number \(result)")
            }
    }
    
    @IBAction func verifyCode(_ sender: Any) {
        let verifyAuthCodeRequest = VerifyAuthCodeRequest(
            phoneNumber: phoneNumberInput.text ?? "",
            email: emailInput.text ?? "",
            verificationCode: verificationCodeInput.text ?? ""
        )
        AppDelegate.reachfive()
            .verifyPasswordlessCode(verifyAuthCodeRequest: verifyAuthCodeRequest)
            .onSuccess { success in
                let alert = AppDelegate.createAlert(title: "Verify code", message: "Success: \(success)")
                self.present(alert, animated: true, completion: nil)
            }
            .onFailure { error in
                let alert = AppDelegate.createAlert(title: "Verify code", message: "Error: \(error.localizedDescription)")
                self.present(alert, animated: true, completion: nil)
            }
            .onComplete { result in
                print("verifyPasswordless \(result)")
            }
    }
}
