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
//    var devices: [DeviceCredential] = [] {
//        didSet {
//            print("devices \(devices)")
//            if devices.isEmpty {
//                listPasskeyLabel.isHidden = true
//                credentialTableview.isHidden = true
//            } else {
//                listPasskeyLabel.isHidden = false
//                credentialTableview.isHidden = false
//            }
//        }
//    }
    
    var clearTokenObserver: NSObjectProtocol?
    var setTokenObserver: NSObjectProtocol?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var familyNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var customIdentifierLabel: UILabel!
    @IBOutlet weak var loginLabel: UILabel!
    @IBOutlet weak var methodLabel: UILabel!
    
//    @IBOutlet weak var listPasskeyLabel: UILabel!
//    @IBOutlet weak var credentialTableview: UITableView!
    
    @IBOutlet weak var profileTabBarItem: UITabBarItem!
    
    @IBOutlet weak var mfaButton: UIButton!
    @IBOutlet weak var passkeyButton: UIButton!
    @IBOutlet weak var startPhoneRegisteringButton: UIButton!
    @IBOutlet weak var startMfaEmailRegisteringButton: UIButton!
    @IBOutlet weak var updatePasswordButton: UIButton!
//    @IBOutlet weak var registerPasskeyButton: UIButton!
    @IBOutlet weak var updatePhoneButton: UIButton!
    @IBOutlet weak var passkey: UIButton!
    @IBOutlet weak var mfa: UIButton!
    
 
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
            .startMfaCredentialRegistration(authToken: authToken, request: StartMfaCredentialRegistrationRequest.PhoneNumber(phoneNumber: phoneNumber))
            .onSuccess {
                self.handleStartVerificationCode(verificationMode: "SMS", authToken: authToken, request: StartMfaCredentialRegistrationRequest.PhoneNumber(phoneNumber: phoneNumber))
            }
            .onFailure { error in
                let alert = AppDelegate.createAlert(title: "Start MFA phone Registration", message: "Error: \(error.message())")
                self.present(alert, animated: true, completion: nil)
            }
    }
    
    private func handleStartVerificationCode(verificationMode: String, authToken: AuthToken, request: StartMfaCredentialRegistrationRequest) {
        let alertController = UIAlertController(title: "Verification Code", message: "Please enter the verification Code you got by \(verificationMode)", preferredStyle: .alert)
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
            switch request {
            case let .PhoneNumber(phoneNumber):
                self.verifyMfaCredential(request: VerifyMfaCredentialRegistrationRequest.PhoneNumber(verificationCode: verificationCode, phoneNumber: phoneNumber), authToken: authToken)
            case let .Email(_):
                self.verifyMfaCredential(request: VerifyMfaCredentialRegistrationRequest.Email(verificationCode: verificationCode), authToken: authToken)
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(submitVerificationCode)
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    @IBAction func doMfaEmailRegistration(_ sender: UIButton) {
        print("ProfileController.startEmailMfaRegistering")
        guard let authToken else {
            print("not logged in")
            return
        }
        AppDelegate.reachfive()
            .startMfaCredentialRegistration(
                authToken: authToken,
                request: StartMfaCredentialRegistrationRequest.Email(redirectUrl: nil)
            )
            .onSuccess {
                self.handleStartVerificationCode(verificationMode: "Email", authToken: authToken, request: StartMfaCredentialRegistrationRequest.Email(redirectUrl: nil))
            }
            .onFailure { error in
                let alert = AppDelegate.createAlert(title: "Start MFA email Registration", message: "Error: \(error.message())")
                self.present(alert, animated: true, completion: nil)
            }
    }
    
    private func verifyMfaCredential(request: VerifyMfaCredentialRegistrationRequest, authToken: AuthToken) {
        switch request {
        case let .Email(verificationCode):
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
        case let .PhoneNumber(verificationCode, phoneNumber):
            AppDelegate.reachfive()
                .verifyMfaCredentialRegistration(authToken: authToken, request: VerifyMfaCredentialRegistrationRequest.PhoneNumber(verificationCode: verificationCode, phoneNumber: phoneNumber))
                .onSuccess {
                    let alert = AppDelegate.createAlert(title: "Verify MFA Phone Number \(phoneNumber) Registration", message: "Success")
                    self.present(alert, animated: true, completion: nil)
                }
                .onFailure { error in
                    let alert = AppDelegate.createAlert(title: "Verify MFA Phone Number \(phoneNumber) Registration", message: "Error: \(error.message())")
                    self.present(alert, animated: true, completion: nil)
                }
        }
    }
    
    override func viewDidLoad() {
        print("ProfileController.viewDidLoad")
        super.viewDidLoad()
        
//        credentialTableview.delegate = self
//        credentialTableview.dataSource = self
        
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
        
        updatePasswordButton.isHidden = false
        passkeyButton.isHidden = false
        mfaButton.isHidden = false
//        registerPasskeyButton.isHidden = false
        updatePhoneButton.isHidden = false
        
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
                
//                self.reloadCredentials(authToken: authToken)
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
//        devices = []
//        credentialTableview.reloadData()
        
        updatePasswordButton.isHidden = true
//        registerPasskeyButton.isHidden = true
        updatePhoneButton.isHidden = true
        startMfaEmailRegisteringButton.isHidden = true
        startPhoneRegisteringButton.isHidden = true
    }
    
//    private func reloadCredentials(authToken: AuthToken) {
//        // Beware that a valid token for profile might not be fresh enough to retrieve the credentials
//        AppDelegate.reachfive().listWebAuthnCredentials(authToken: authToken).onSuccess { listCredentials in
//                self.devices = listCredentials
//
//                self.profileTabBarItem.image = SandboxTabBarController.loggedIn
//                self.profileTabBarItem.selectedImage = self.profileTabBarItem.image
//
//                //TODO comprendre pourquoi on fait un async. En a-t-on vraiment besoin ?
//                DispatchQueue.main.async {
//                    self.credentialTableview.reloadData()
//                }
//            }
//            .onFailure { error in
//                self.devices = []
//                self.profileTabBarItem.image = SandboxTabBarController.loggedInButNoPasskey
//                self.profileTabBarItem.selectedImage = self.profileTabBarItem.image
//
//                print("getCredentials error = \(error.message())")
//            }
//    }
//
//    @available(iOS 16.0, *)
//    @IBAction func registerNewPasskey(_ sender: Any) {
//        print("registerNewPasskey")
//        guard let window = view.window else { fatalError("The view was not in the app's view hierarchy!") }
//        guard let authToken else {
//            print("not logged in")
//            return
//        }
//        AppDelegate.reachfive()
//            .getProfile(authToken: authToken)
//            .onSuccess { profile in
//                let friendlyName = ProfileController.username(profile: profile)
//
//                let alert = UIAlertController(
//                    title: "Register New Passkey",
//                    message: "Name the passkey",
//                    preferredStyle: .alert
//                )
//                // init the text field with the profile's identifier
//                alert.addTextField { field in
//                    field.text = friendlyName
//                }
//                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//                let registerAction = UIAlertAction(title: "Add", style: .default) { [unowned alert] (_) in
//                    let textField = alert.textFields?[0]
//
//                    AppDelegate.reachfive().registerNewPasskey(withRequest: NewPasskeyRequest(anchor: window, friendlyName: textField?.text ?? friendlyName, origin: "ProfileController.registerNewPasskey"), authToken: authToken)
//                        .onSuccess { _ in
//                            self.reloadCredentials(authToken: authToken)
//                        }
//                        .onFailure { error in
//                            switch error {
//                            case .AuthCanceled: return
//                            default:
//                                let alert = AppDelegate.createAlert(title: "Register New Passkey", message: "Error: \(error.message())")
//                                self.present(alert, animated: true)
//                            }
//                        }
//                }
//                alert.addAction(registerAction)
//                alert.preferredAction = registerAction
//                self.present(alert, animated: true)
//            }
//            .onFailure { error in
//                // the token is probably expired, but it is still possible that it can be refreshed
//                self.didLogout()
//                self.profileTabBarItem.image = SandboxTabBarController.tokenExpiredButRefreshable
//                self.profileTabBarItem.selectedImage = self.profileTabBarItem.image
//                print("getProfile error = \(error.message())")
//            }
//    }
//
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
//    
//    @IBAction func logoutAction(_ sender: Any) {
//        AppDelegate.reachfive().logout()
//            .onComplete { result in
//                AppDelegate.storage.clear(key: SecureStorage.authKey)
//                self.navigationController?.popViewController(animated: true)
//            }
//    }
}
//
//extension ProfileController: UITableViewDelegate {
//    // method to run when table view cell is tapped
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//    }
//}
//
//extension ProfileController: UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        devices.count
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let cell = credentialTableview.dequeueReusableCell(withIdentifier: "credentialCell") else {
//            fatalError("No credentialCell cell")
//        }
//        
//        let friendlyName = devices[indexPath.row].friendlyName
//        if #available(iOS 14.0, *) {
//            var content = cell.defaultContentConfiguration()
//            content.text = friendlyName
//            cell.contentConfiguration = content
//        } else {
//            cell.textLabel?.text = friendlyName
//        }
//        return cell
//    }
//    
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete {
//            guard let authToken else { return }
//            let element = devices[indexPath.row]
//            AppDelegate.reachfive().deleteWebAuthnRegistration(id: element.id, authToken: authToken)
//                .onSuccess { _ in
//                    self.devices.remove(at: indexPath.row)
//                    print("did remove passkey \(element.friendlyName)")
//                    tableView.deleteRows(at: [indexPath], with: .fade)
//                }
//                .onFailure { error in print(error.message()) }
//        }
//    }
//}
