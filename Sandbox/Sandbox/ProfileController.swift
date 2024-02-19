import UIKit
import IdentitySdkCore
import BrightFutures

//TODO
//      - déplacer le bouton login with refresh ici pour que, même logué, on puisse afficher les passkey (qui sont expirées)
//      - faire du pull-to-refresh soit sur la table des clés soit carrément sur tout le profil (déclencher le refresh token)
//      - ajouter une option conversion vers un mdp fort automatique et vers SIWA
//      - voir les SLO liés et bouton pour les délier
//      - supprimer le bouton de modification du numéro de téléphone et le mettre en icône crayon à côté de sa valeur affichée (seulement si elle est présente)
//      - faire la même chose pour l'email et custom identifier
//      - pour l'extraction du username, voir la conf backend si la feature SMS est activée.
//      - marquer spécialement l'identifiant principal dans l'UI
//      - ajouter un bouton + dans la table des clés pour en ajouter une (ou carrément supprimer le bouton "register passkey")
//      - ajouter un bouton modifier à la table pour pouvoir plus visuellement supprimer des clés
//      - faire en sorte que les textes (nom, prénom...) soient copiable
class ProfileController: UIViewController {
    var authToken: AuthToken?
    
    var clearTokenObserver: NSObjectProtocol?
    var setTokenObserver: NSObjectProtocol?
    
    var emailVerifyNotification: NSObjectProtocol?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var familyNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var customIdentifierLabel: UILabel!
    @IBOutlet weak var loginLabel: UILabel!
    @IBOutlet weak var methodLabel: UILabel!
    
    @IBOutlet weak var profileTabBarItem: UITabBarItem!
    
    @IBOutlet weak var mfaButton: UIButton!
    @IBOutlet weak var passkeyButton: UIButton!
    @IBOutlet weak var startPhoneRegisteringButton: UIButton!
    @IBOutlet weak var startMfaEmailRegisteringButton: UIButton!
    @IBOutlet weak var editProfileButton: UIButton!
    @IBOutlet weak var passkey: UIButton!
    @IBOutlet weak var mfa: UIButton!
    
    
    override func viewDidLoad() {
        print("ProfileController.viewDidLoad")
        super.viewDidLoad()
        
        emailVerifyNotification = NotificationCenter.default.addObserver(forName: .DidReceiveMfaVerifyEmail, object: nil, queue: nil) {
            (note) in
            if let result = note.userInfo?["result"], let result = result as? Result<(), ReachFiveError> {
                self.dismiss(animated: true)
                switch result {
                case .success():
                    let alert = AppDelegate.createAlert(title: "Email mfa registering success", message: "Email mfa registering success")
                    self.present(alert, animated: true)
                case .failure(let error):
                    let alert = AppDelegate.createAlert(title: "Email mfa registering failed", message: "Error: \(error.message())")
                    self.present(alert, animated: true)
                }
            }
        }
        
        //TODO: mieux gérer les notifications pour ne pas en avoir plusieurs qui se déclenche pour le même évènement
        clearTokenObserver = NotificationCenter.default.addObserver(forName: .DidClearAuthToken, object: nil, queue: nil) { _ in
            self.didLogout()
        }
        
        setTokenObserver = NotificationCenter.default.addObserver(forName: .DidSetAuthToken, object: nil, queue: nil) { _ in
            self.didLogin()
        }
        
        authToken = AppDelegate.storage.get(key: SecureStorage.authKey)
        if authToken != nil {
            profileTabBarItem.image = SandboxTabBarController.tokenPresent
            profileTabBarItem.selectedImage = profileTabBarItem.image
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("ProfileController.viewWillAppear")
        authToken = AppDelegate.storage.get(key: SecureStorage.authKey)
        guard let authToken else {
            print("not logged in")
            return
        }
        
        mfaButton.isHidden = false
        editProfileButton.isHidden = false
        
        startPhoneRegisteringButton.isHidden = true
        startMfaEmailRegisteringButton.isHidden = true
        
        AppDelegate.reachfive()
            .getProfile(authToken: authToken)
            .onSuccess { profile in
                self.nameLabel.text = profile.givenName
                self.familyNameLabel.text = profile.familyName
                if let email = profile.email {
                    self.emailLabel.text = email
                    self.emailLabel.text?.append(profile.emailVerified == true ? " ✔︎" : " ✘")
                    self.startMfaEmailRegisteringButton.isHidden = false
                }
                if let phoneNumber = profile.phoneNumber {
                    self.phoneNumberLabel.text = phoneNumber
                    self.phoneNumberLabel.text?.append(profile.phoneNumberVerified == true ? " ✔︎" : " ✘")
                    self.startPhoneRegisteringButton.isHidden = false
                }
                self.customIdentifierLabel.text = profile.customIdentifier
                if let loginSummary = profile.loginSummary, let lastLogin = loginSummary.lastLogin {
                    self.loginLabel.text = self.format(date: lastLogin)
                    self.methodLabel.text = loginSummary.lastProvider
                }
            }
            .onFailure { error in
                // the token is probably expired, but it is still possible that it can be refreshed
                self.didLogout()
                self.profileTabBarItem.image = SandboxTabBarController.tokenExpiredButRefreshable
                self.profileTabBarItem.selectedImage = self.profileTabBarItem.image
                print("getProfile error = \(error.message())")
            }
        
        super.viewWillAppear(animated)
    }
    
    func didLogin() {
        print("ProfileController.didLogin")
        authToken = AppDelegate.storage.get(key: SecureStorage.authKey)
    }
    
    func didLogout() {
        print("ProfileController.didLogout")
        authToken = nil
        nameLabel.text = nil
        familyNameLabel.text = nil
        emailLabel.text = nil
        phoneNumberLabel.text = nil
        customIdentifierLabel.text = nil
        loginLabel.text = nil
        methodLabel.text = nil
        passkeyButton.isHidden = true
        mfaButton.isHidden = true
        editProfileButton.isHidden = true
//        updatePasswordButton.isHidden = true
//        updatePhoneButton.isHidden = true
        startMfaEmailRegisteringButton.isHidden = true
        startPhoneRegisteringButton.isHidden = true
    }
    
    @IBAction func doMfaPhoneRegistration(_ sender: UIButton) {
        print("ProfileController.startMfaPhoneRegistration")
        guard let authToken else {
            print("not logged in")
            return
        }
        let phoneNumber = phoneNumberLabel.text
        guard let phoneNumber else {
            print("phone number cannot be empty")
            return
        }
        AppDelegate.reachfive()
            .mfaStartRegistering(credential: .PhoneNumber(phoneNumber), authToken: authToken)
            .onSuccess { mfaStartCredentialRegistrationResponse in
                self.handleStartVerificationCode(mfaStartCredentialRegistrationResponse: mfaStartCredentialRegistrationResponse, credentialVerification: .SMS, authToken: authToken)
            }
            .onFailure { error in
                let alert = AppDelegate.createAlert(title: "Start MFA phone Registration", message: "Error: \(error.message())")
                self.present(alert, animated: true, completion: nil)
            }
    }
    
    private func handleStartVerificationCode(mfaStartCredentialRegistrationResponse: MfaStartCredentialRegistrationResponse, credentialVerification: CredentialVerification, authToken: AuthToken) {
        var alertController: UIAlertController
        if(mfaStartCredentialRegistrationResponse.status == Status.enabled.rawValue) {
            alertController = AppDelegate.createAlert(title: "MFA \(credentialVerification) enabled", message: "Success")
        }
        else {
            alertController = UIAlertController(title: "Verification Code", message: "Please enter the verification Code you got by \(credentialVerification)", preferredStyle: .alert)
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
                
                self.verifyMfaCredential(verificationCode: verificationCode, credentialVerification: credentialVerification, authToken: authToken)
            }
            alertController.addAction(cancelAction)
            alertController.addAction(submitVerificationCode)
        }
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    @IBAction func doMfaEmailRegistration(_ sender: UIButton) {
        print("ProfileController.startEmailMfaRegistering")
        guard let authToken else {
            print("not logged in")
            return
        }
        AppDelegate.reachfive()
            .mfaStartRegistering(credential: .Email(), authToken: authToken)
            .onSuccess { mfaStartCredentialRegistrationResponse in
                self.handleStartVerificationCode(mfaStartCredentialRegistrationResponse: mfaStartCredentialRegistrationResponse, credentialVerification: .Email, authToken: authToken)
            }
            .onFailure { error in
                let alert = AppDelegate.createAlert(title: "Start MFA email Registration", message: "Error: \(error.message())")
                self.present(alert, animated: true, completion: nil)
            }
    }
    
    private func verifyMfaCredential(verificationCode: String, credentialVerification: CredentialVerification, authToken: AuthToken) {
        AppDelegate.reachfive()
            .mfaVerifyRegistering(credential: credentialVerification, verificationCode: verificationCode, authToken: authToken)
            .onSuccess {
                let alert = AppDelegate.createAlert(title: "Verify MFA \(credentialVerification) Registration", message: "Success")
                self.present(alert, animated: true, completion: nil)
            }
            .onFailure { error in
                let alert = AppDelegate.createAlert(title: "Verify MFA \(credentialVerification) Registration", message: "Error: \(error.message())")
                self.present(alert, animated: true, completion: nil)
            }
    }
    
    internal static func username(profile: Profile) -> String {
        let username: String
        // here the priority for phone number over email follows the backend rule
        if let phone = profile.phoneNumber {
            username = phone
        } else if let email = profile.email {
            username = email
        } else {
            username = "Should have had an identifier"
        }
        return username
    }
    
    private func format(date: Int) -> String {
        let lastLogin = Date(timeIntervalSince1970: TimeInterval(date / 1000))
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        dateFormatter.locale = Locale(identifier: "en_GB")
        return dateFormatter.string(from: lastLogin)
    }
}
