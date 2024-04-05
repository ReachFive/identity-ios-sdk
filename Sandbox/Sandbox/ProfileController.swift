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
//      - Ajouter des infos sur le jeton dans une nouvelle page
class ProfileController: UIViewController {
    var authToken: AuthToken?
    
    var profile: Profile = Profile() {
        didSet {
            self.applyMainSectionSnapshot()
        }
    }
    
    //TODO quand il n'y en a pas ou que c'est pas frais on ne voit pas la section.
    // Est-ce dommage et devrait-on réintroduire les en-tête de section ?
    var passkeys: [DeviceCredential] = [] {
        didSet {
            self.applyPasskeySectionSnapshot()
        }
    }
    
    var mfaCredentials: [MfaCredentialItem] = [] {
        didSet {
            self.applyMfaSectionSnapshot()
        }
    }
    
    var clearTokenObserver: NSObjectProtocol?
    var setTokenObserver: NSObjectProtocol?
    
    var emailVerifyNotification: NSObjectProtocol?
    
    var propertiesToDisplay: [Field] = []
    let mfaRegistrationAvailable = ["Email", "Phone Number"]
    
    @IBOutlet weak var otherOptions: UITableView!
    
    @IBOutlet weak var profileTabBarItem: UITabBarItem!
    @IBOutlet weak var collectionView: UICollectionView!
    //Mettre une table list au lieu des boutons
    @IBOutlet weak var mfaButton: UIButton!
    @IBOutlet weak var passkeyButton: UIButton!
    @IBOutlet weak var editProfileButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    var dataSource: UICollectionViewDiffableDataSource<Section, Row>! = nil
    
    private func rows() -> [Row] {
        return [
            // faire une donnée spécifique pour les identifiants pour savoir s'ils sont vérifiés, s'ils sont enrollés MFA...
            Row(title: "Email", leaf: Value(profile.email?.appending(profile.emailVerified == true ? " ✔︎" : " ✘"))),
            Row(title: "Phone Number", leaf: Value(profile.phoneNumber?.appending(profile.phoneNumberVerified == true ? " ✔︎" : " ✘"))),
            Row(title: "Custom Identifier", leaf: Value(profile.customIdentifier)),
            Row(title: "Given Name", leaf: Value(profile.givenName)),
            Row(title: "Family Name", leaf: Value(profile.familyName)),
            Row(title: "Last logged In", leaf: Value(profile.loginSummary?.lastLogin.map { date in self.format(date: date) } ?? "")),
            Row(title: "Method", leaf: Value(profile.loginSummary?.lastProvider)),
        ]
    }
    
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
        
        authToken = AppDelegate.storage.getToken()
        if authToken != nil {
            profileTabBarItem.image = SandboxTabBarController.tokenPresent
            profileTabBarItem.selectedImage = profileTabBarItem.image
        }
        
        configureCollectionView()
        configureDataSource()
        applySectionSnapshot()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("ProfileController.viewWillAppear")
        fetchProfile()
    }
    
    func fetchProfile() {
        print("ProfileController.fetchProfile")
        
        authToken = AppDelegate.storage.getToken()
        guard let authToken else {
            print("not logged in")
            return
        }
        AppDelegate.reachfive()
            .getProfile(authToken: authToken)
            .onSuccess { profile in
                self.profile = profile
                self.mfaButton.isHidden = false
                self.editProfileButton.isHidden = false
                self.passkeyButton.isHidden = false
                
                self.fetchExtraProfileData(authToken: authToken)
            }
            .onFailure { error in
                self.didLogout()
                if authToken.refreshToken != nil {
                    // the token is probably expired, but it is still possible that it can be refreshed
                    self.profileTabBarItem.image = SandboxTabBarController.tokenExpiredButRefreshable
                    self.profileTabBarItem.selectedImage = self.profileTabBarItem.image
                } else {
                    self.profileTabBarItem.image = SandboxTabBarController.loggedOut
                    self.profileTabBarItem.selectedImage = self.profileTabBarItem.image
                }
                print("getProfile error = \(error.message())")
            }
    }
    
    private func fetchExtraProfileData(authToken: AuthToken) {
        // Use listWebAuthnCredentials to test if token is fresh
        // A fresh token is also needed for updating the profile and registering MFA credentials
        AppDelegate.reachfive().listWebAuthnCredentials(authToken: authToken)
            .onSuccess { passkeys in
                self.passkeys = passkeys
                self.passkeyButton.isEnabled = true
                self.profileTabBarItem.image = SandboxTabBarController.loggedIn
                self.profileTabBarItem.selectedImage = self.profileTabBarItem.image
            }
            .onFailure { _ in
                self.passkeyButton.isEnabled = false
                self.profileTabBarItem.image = SandboxTabBarController.loggedInButNotFresh
                self.profileTabBarItem.selectedImage = self.profileTabBarItem.image
            }
        
        AppDelegate.reachfive()
            .mfaListCredentials(authToken: authToken)
            .onSuccess { response in
                self.mfaCredentials = response.credentials
            }
    }
    
    func didLogin() {
        print("ProfileController.didLogin")
        authToken = AppDelegate.storage.getToken()
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
                AppDelegate.storage.removeToken()
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

// MARK: - Gestion CollectionView
extension ProfileController {
    func configureCollectionView() {
        collectionView.collectionViewLayout = listLayout()
        collectionView.delegate = self
    }
    
    func configureDataSource() {
        
        let containerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Row>{ (cell, indexPath, menuItem) in
            // Populate the cell with our item description.
            var contentConfiguration = cell.defaultContentConfiguration()
            contentConfiguration.text = menuItem.title
            contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .headline)
            cell.contentConfiguration = contentConfiguration
            
            let disclosureOptions = UICellAccessory.OutlineDisclosureOptions(style: .header)
            cell.accessories = [.outlineDisclosure(options: disclosureOptions)]
            cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
        }
        
        let cellRegistration = UICollectionView.CellRegistration<ProfileDataCell, Row>{ cell, indexPath, menuItem in
            cell.configure(with: menuItem)
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Row>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: Row) -> UICollectionViewCell? in
            // Return the cell.
            if item.subitems.isEmpty {
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            } else {
                return collectionView.dequeueConfiguredReusableCell(using: containerCellRegistration, for: indexPath, item: item)
            }
        }
    }
    
    func listLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        //TODO centrer au milieu de l'écran si grand écran (au lieu d'avoir le titre tout à gauche et la valeur tout à droite)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(44))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    private func applySectionSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Row>()
        snapshot.appendSections(Section.allCases)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func applyMfaSectionSnapshot() {
        var mfaSectionSnapshot = NSDiffableDataSourceSectionSnapshot<Row>()
        let mfaRow = Row(title: "Mfa", subitems: mfaCredentials.map { mfa in Row(title: mfa.friendlyName) })
        mfaSectionSnapshot.addItems([mfaRow], to: nil)
        dataSource.apply(mfaSectionSnapshot, to: Section.mfa, animatingDifferences: true)
    }
    
    private func applyPasskeySectionSnapshot() {
        var passkeySectionSnapshot = NSDiffableDataSourceSectionSnapshot<Row>()
        let passkeyRow = Row(title: "Passkeys", subitems: passkeys.map { passkey in Row(title: passkey.friendlyName) })
        passkeySectionSnapshot.addItems([passkeyRow], to: nil)
        dataSource.apply(passkeySectionSnapshot, to: Section.passkey, animatingDifferences: true)
    }
    
    private func applyMainSectionSnapshot() {
        var mainSectionSnapshot = NSDiffableDataSourceSectionSnapshot<Row>()
        //TODO séparer les identifiants en une section à part
        let rows = rows()
        
        mainSectionSnapshot.addItems(rows, to: nil)
        dataSource.apply(mainSectionSnapshot, to: Section.main, animatingDifferences: true)
    }
}

// MARK: - Utilitaire DataSource
extension NSDiffableDataSourceSectionSnapshot<Row> {
    mutating func addItems(_ menuItems: [Row], to parent: Row?) {
        self.append(menuItems, to: parent)
        for menuItem in menuItems {
            print("\(menuItem.title): \(menuItem.leaf?.value). \(menuItem.subitems)")
        }
        for menuItem in menuItems where !menuItem.subitems.isEmpty {
            addItems(menuItem.subitems, to: menuItem)
        }
    }
}

// MARK: - Définition des données de la collection
enum Section: CaseIterable {
    case main
    case passkey
    case mfa
}

class Row: Hashable {
    let title: String
    let subitems: [Row]
    let leaf: Value?
    
    init(title: String,
         leaf: Value? = nil,
         subitems: [Row] = []) {
        self.title = title
        self.leaf = leaf
        self.subitems = subitems
        
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    static func ==(lhs: Row, rhs: Row) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    private let identifier = UUID()
}

class Value {
    let value: String?
    //TODO mettre les actions
//        let actions: [UIAction]
    init(_ value: String?) {
        self.value = value
    }
}

// MARK: - Cellule d'affichage
class ProfileDataCell: UICollectionViewListCell {
    let title: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        
        return label
    }()
    
    let value: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        
        return label
    }()
    
    public func configure(with row: Row) {
        title.text = row.title
        value.text = row.leaf?.value
        title.translatesAutoresizingMaskIntoConstraints = false
        value.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(title)
        contentView.addSubview(value)
        
        title.font = UIFont.preferredFont(forTextStyle: .body)
        value.font = UIFont.preferredFont(forTextStyle: .body)
        
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            value.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
}