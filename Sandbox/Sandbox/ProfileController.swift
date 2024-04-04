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
            let snapshot = snapshot(profile: profile)
            self.dataSource.apply(snapshot, to: .main, animatingDifferences: true)
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
    @IBOutlet weak var mfaButton: UIButton!
    @IBOutlet weak var passkeyButton: UIButton!
    @IBOutlet weak var editProfileButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    var dataSource: UICollectionViewDiffableDataSource<Section, Row>! = nil
    
    enum Section {
        case main
    }
    
    private func rows(profile: Profile) -> [Row] {
        return [
            Row(title: "Email", leaf: Value(profile.email?.appending(profile.emailVerified == true ? " ✔︎" : " ✘"))),
            Row(title: "Phone Number", leaf: Value(profile.phoneNumber?.appending(profile.phoneNumberVerified == true ? " ✔︎" : " ✘"))),
            Row(title: "Custom Identifier", leaf: Value(profile.customIdentifier)),
            Row(title: "Given Name", leaf: Value(profile.givenName)),
            Row(title: "Family Name", leaf: Value(profile.familyName)),
            Row(title: "Last logged In", leaf: Value(profile.loginSummary?.lastLogin.map { date in self.format(date: date) } ?? "")),
            Row(title: "Method", leaf: Value(profile.loginSummary?.lastProvider)),
        ]
    }
    
    class Value {
        let value: String?
//        let actions: [UIAction]
        init(_ value: String?) {
            self.value = value
        }
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

//        self.profileData.delegate = self
//        self.profileData.dataSource = self
        
        configureCollectionView()
        configureDataSource()
    }
    
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
        
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Row>{ cell, indexPath, menuItem in
            // Populate the cell with our item description.
            var contentConfiguration = cell.defaultContentConfiguration()
            contentConfiguration.text = menuItem.title
            contentConfiguration.secondaryText = menuItem.leaf?.value
            cell.contentConfiguration = contentConfiguration
            cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
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
        
        // load our initial data
        let snapshot = snapshot(profile: profile)
        self.dataSource.apply(snapshot, to: .main, animatingDifferences: false)
    }
    
    func listLayout() -> UICollectionViewLayout {
        let listConfiguration = UICollectionLayoutListConfiguration(appearance: .sidebar)
        let layout = UICollectionViewCompositionalLayout.list(using: listConfiguration)
        return layout
    }
    
    func twoColumnsLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
        let spacing = CGFloat(10)
        group.interItemSpacing = .fixed(spacing)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    //voir plutôt les Orthogonal Sections
    func nestedLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let leadingItem = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.7),
                    heightDimension: .fractionalHeight(1.0)))
            leadingItem.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            
            let trailingItem = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(0.3)))
            trailingItem.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            let trailingGroup = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.3),
                    heightDimension: .fractionalHeight(1.0)),
                subitem: trailingItem, count: 2)
            
            let nestedGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(0.4)),
                subitems: [leadingItem, trailingGroup])
            let section = NSCollectionLayoutSection(group: nestedGroup)
            return section
            
        }
        return layout
    }
    
    func orthogonalSectionsLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let leadingItem = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.7),
                    heightDimension: .fractionalHeight(1.0)))
            leadingItem.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            
            let trailingItem = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(0.3)))
            trailingItem.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            let trailingGroup = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.3),
                    heightDimension: .fractionalHeight(1.0)),
                subitem: trailingItem, count: 2)
            
            let containerGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.85),
                    heightDimension: .fractionalHeight(0.4)),
                subitems: [leadingItem, trailingGroup])
            let section = NSCollectionLayoutSection(group: containerGroup)
            section.orthogonalScrollingBehavior = .continuous
            
            return section
            
        }
        return layout
    }
    
    func myLayout() -> UICollectionViewLayout {
        
        let layout = UICollectionViewCompositionalLayout {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let leadingItem = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1.0)))
//            leadingItem.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            
            let trailingItem = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1.0)))
//            trailingItem.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            
            let nestedGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44)),
                subitems: [leadingItem, trailingItem])
            let section = NSCollectionLayoutSection(group: nestedGroup)

/*
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(44)),
                elementKind: "section-header-element-kind",
                alignment: .top)
            let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(44)),
                elementKind: "section-footer-element-kind",
                alignment: .bottom)
            sectionHeader.pinToVisibleBounds = true
            sectionHeader.zIndex = 2
            section.boundarySupplementaryItems = [sectionHeader, sectionFooter]
        */
            
            return section
            
        }
        return layout
    }
    
    func snapshot(profile: Profile) -> NSDiffableDataSourceSectionSnapshot<Row> {
        var snapshot = NSDiffableDataSourceSectionSnapshot<Row>()
        let rows = rows(profile: profile)
        
        func addItems(_ menuItems: [Row], to parent: Row?) {
            snapshot.append(menuItems, to: parent)
            for menuItem in menuItems where !menuItem.subitems.isEmpty {
                addItems(menuItem.subitems, to: menuItem)
            }
        }
        
        addItems(rows, to: nil)
        return snapshot
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
//                self.profileData.reloadData()
                self.setStatusImage(authToken: authToken)
                self.mfaButton.isHidden = false
                self.editProfileButton.isHidden = false
                self.passkeyButton.isHidden = false
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
    
    private func setStatusImage(authToken: AuthToken) {
        // Use listWebAuthnCredentials to test if token is fresh
        // A fresh token is also needed for updating the profile and registering MFA credentials
        AppDelegate.reachfive().listWebAuthnCredentials(authToken: authToken).onSuccess { _ in
                self.passkeyButton.isEnabled = true
                self.profileTabBarItem.image = SandboxTabBarController.loggedIn
                self.profileTabBarItem.selectedImage = self.profileTabBarItem.image
            }
            .onFailure { error in
                self.passkeyButton.isEnabled = false
                self.profileTabBarItem.image = SandboxTabBarController.loggedInButNotFresh
                self.profileTabBarItem.selectedImage = self.profileTabBarItem.image
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
//        self.profileData.reloadData()
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
