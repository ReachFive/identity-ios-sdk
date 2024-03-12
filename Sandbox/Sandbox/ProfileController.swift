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
//      - réparer les icônes de statut de connexion
//      - mettre les nouvelles méthodes dédiés au jeton (storage.setToken...)
//      - Refaire la page d'ajout d'un nouveau tel au MFA
//      - Ajouter des infos sur le jeton dans une nouvelle page
class ProfileController: UIViewController {
    var authToken: AuthToken?
    var profile: Profile? = nil {
        didSet {
            guard let profile else {
                propertiesToDisplay = []
                return
            }
            self.propertiesToDisplay = [
                Field(name: "Email", value: profile.email?.appending(profile.emailVerified == true ? " ✔︎" : " ✘")),
                Field(name: "Phone Number", value: profile.phoneNumber?.appending(profile.phoneNumberVerified == true ? " ✔︎" : " ✘")),
                Field(name: "Custom Identifier", value: profile.customIdentifier),
                Field(name: "Given Name", value: profile.givenName),
                Field(name: "Family Name", value: profile.familyName),
                Field(name: "Last logged In", value: self.format(date: profile.loginSummary?.lastLogin ?? 0)),
                Field(name: "Method", value: profile.loginSummary?.lastProvider)
            ]
        }
    }
    
    var clearTokenObserver: NSObjectProtocol?
    var setTokenObserver: NSObjectProtocol?
    
    var emailVerifyNotification: NSObjectProtocol?
    
    var propertiesToDisplay: [Field] = []
    let mfaRegistrationAvailable = ["Email", "Phone Number"]
    
    @IBOutlet weak var otherOptions: UITableView!
    
    @IBOutlet weak var profileTabBarItem: UITabBarItem!
    @IBOutlet var profileData: UITableView!
    @IBOutlet weak var mfaButton: UIButton!
    @IBOutlet weak var passkeyButton: UIButton!
    @IBOutlet weak var editProfileButton: UIButton!
    
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
                    self.fetchProfile()
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
        
        self.profileData.delegate = self
        self.profileData.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("ProfileController.viewWillAppear")
        
        mfaButton.isHidden = false
        editProfileButton.isHidden = false
        
        fetchProfile()
    }
    
    func fetchProfile() {
        print("ProfileController.fetchProfile")
        
        authToken = AppDelegate.storage.get(key: SecureStorage.authKey)
        guard let authToken else {
            print("not logged in")
            return
        }
        AppDelegate.reachfive()
            .getProfile(authToken: authToken)
            .onSuccess { profile in
                self.profile = profile
                self.profileData.reloadData()
            }
            .onFailure { error in
                // the token is probably expired, but it is still possible that it can be refreshed
                self.didLogout()
                self.profileTabBarItem.image = SandboxTabBarController.tokenExpiredButRefreshable
                self.profileTabBarItem.selectedImage = self.profileTabBarItem.image
                print("getProfile error = \(error.message())")
            }
    }
    
    func didLogin() {
        print("ProfileController.didLogin")
        authToken = AppDelegate.storage.get(key: SecureStorage.authKey)
    }
    
    func didLogout() {
        print("ProfileController.didLogout")
        authToken = nil
        profile = Profile()
        passkeyButton.isHidden = true
        mfaButton.isHidden = true
        editProfileButton.isHidden = true
    }
    
    @IBAction func logoutAction(_ sender: Any) {
        AppDelegate.reachfive().logout()
            .onComplete { result in
                AppDelegate.storage.clear(key: SecureStorage.authKey)
                self.navigationController?.popViewController(animated: true)
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
}
