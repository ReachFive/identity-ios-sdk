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
            self.propertiesToDisplay = [
                Field(name: "Email", value: profile.email?.appending(profile.emailVerified == true ? " ✔︎" : " ✘")),
                Field(name: "Phone Number", value: profile.phoneNumber?.appending(profile.phoneNumberVerified == true ? " ✔︎" : " ✘")),
                Field(name: "Custom Identifier", value: profile.customIdentifier),
                Field(name: "Given Name", value: profile.givenName),
                Field(name: "Family Name", value: profile.familyName),
                Field(name: "Last logged In", value: profile.loginSummary?.lastLogin.map { date in self.format(date: date) } ?? ""),
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
    @IBOutlet weak var collection: UICollectionView!
    @IBOutlet weak var mfaButton: UIButton!
    @IBOutlet weak var passkeyButton: UIButton!
    @IBOutlet weak var editProfileButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    var dataSource: UICollectionViewDiffableDataSource<Section, OutlineItem>! = nil
    var outlineCollectionView: UICollectionView! = nil
    
    enum Section {
        case main
    }
    
    private lazy var menuItems: [OutlineItem] = {
        // voir pour faire une section par élément, avec le titre et la valeur sur deux colonnes
        // voir comment on peut implémenter les actions
        return [
            OutlineItem(title: "Email"),
            OutlineItem(title: "Phone Number"),
            OutlineItem(title: "Custom Identifier"),
            OutlineItem(title: "Given Name"),
            OutlineItem(title: "Family Name"),
            OutlineItem(title: "Last logged In"),
            OutlineItem(title: "Method"),
/*
            OutlineItem(title: "Compositional Layout", subitems: [
                OutlineItem(title: "Getting Started", subitems: [
                    OutlineItem(title: "PasskeyCredentialController", viewController: PasskeyCredentialController.self),
                    OutlineItem(title: "Inset Items Grid",
                        viewController: InsetItemsGridViewController.self),
                    OutlineItem(title: "Two-Column Grid", viewController: TwoColumnViewController.self),
                    OutlineItem(title: "Per-Section Layout", subitems: [
                        OutlineItem(title: "Distinct Sections",
                            viewController: DistinctSectionsViewController.self),
                        OutlineItem(title: "Adaptive Sections",
                            viewController: AdaptiveSectionsViewController.self)
                    ])
                ]),
        */
/*
                OutlineItem(title: "Advanced Layouts", subitems: [
                    OutlineItem(title: "Supplementary Views", subitems: [
                        OutlineItem(title: "Item Badges",
                            viewController: ItemBadgeSupplementaryViewController.self),
                        OutlineItem(title: "Section Headers/Footers",
                            viewController: SectionHeadersFootersViewController.self),
                        OutlineItem(title: "Pinned Section Headers",
                            viewController: PinnedSectionHeaderFooterViewController.self)
                    ]),
                    OutlineItem(title: "Section Background Decoration",
                        viewController: SectionDecorationViewController.self),
                    OutlineItem(title: "Nested Groups",
                        viewController: NestedGroupsViewController.self),
                    OutlineItem(title: "Orthogonal Sections", subitems: [
                        OutlineItem(title: "Orthogonal Sections",
                            viewController: OrthogonalScrollingViewController.self),
                        OutlineItem(title: "Orthogonal Section Behaviors",
                            viewController: OrthogonalScrollBehaviorViewController.self)
                    ])
                ]),
            */
/*
                OutlineItem(title: "Conference App", subitems: [
                    OutlineItem(title: "Videos",
                        viewController: ConferenceVideoSessionsViewController.self),
                    OutlineItem(title: "News", viewController: ConferenceNewsFeedViewController.self)
                ])
            ]),
            */
/*
            OutlineItem(title: "Diffable Data Source", subitems: [
                OutlineItem(title: "Mountains Search", viewController: MountainsViewController.self),
                OutlineItem(title: "Settings: Wi-Fi", viewController: WiFiSettingsViewController.self),
                OutlineItem(title: "Insertion Sort Visualization",
                    viewController: InsertionSortViewController.self),
                OutlineItem(title: "UITableView: Editing",
                    viewController: TableViewEditingViewController.self)
            ]),
            OutlineItem(title: "Lists", subitems: [
                OutlineItem(title: "Simple List", viewController: SimpleListViewController.self),
                OutlineItem(title: "Reorderable List", viewController: ReorderableListViewController.self),
                OutlineItem(title: "List Appearances", viewController: ListAppearancesViewController.self),
                OutlineItem(title: "List with Custom Cells", viewController: CustomCellListViewController.self)
            ]),
            OutlineItem(title: "Outlines", subitems: [
                OutlineItem(title: "Emoji Explorer", viewController: EmojiExplorerViewController.self),
                OutlineItem(title: "Emoji Explorer - List", viewController: EmojiExplorerListViewController.self)
            ]),
            OutlineItem(title: "Cell Configurations", subitems: [
                OutlineItem(title: "Custom Configurations", viewController: CustomConfigurationViewController.self)
            ])
        */
        ]
    }()
    
    struct LeafItem {
        let value: String
//        let actions: [UIAction]
    }
    
    class OutlineItem: Hashable {
        let title: String
        let subitems: [OutlineItem]
        let leaf: LeafItem?
        
        init(title: String,
             leaf: LeafItem? = nil,
             subitems: [OutlineItem] = []) {
            self.title = title
            self.leaf = leaf
            self.subitems = subitems
        
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }
        
        static func ==(lhs: OutlineItem, rhs: OutlineItem) -> Bool {
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
        let collectionView = UICollectionView(frame: containerView.bounds, collectionViewLayout: twoColumnsLayout())
        containerView.addSubview(collectionView)
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.backgroundColor = .systemGroupedBackground
        self.outlineCollectionView = collectionView
        collectionView.delegate = self
    }
    
    func configureDataSource() {
        
        let containerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, OutlineItem>{ (cell, indexPath, menuItem) in
            // Populate the cell with our item description.
            var contentConfiguration = cell.defaultContentConfiguration()
            contentConfiguration.text = menuItem.title
            contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .headline)
            cell.contentConfiguration = contentConfiguration
            
            let disclosureOptions = UICellAccessory.OutlineDisclosureOptions(style: .header)
            cell.accessories = [.outlineDisclosure(options: disclosureOptions)]
            cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
        }
        
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, OutlineItem>{ cell, indexPath, menuItem in
            // Populate the cell with our item description.
            var contentConfiguration = cell.defaultContentConfiguration()
            contentConfiguration.text = menuItem.title
            cell.contentConfiguration = contentConfiguration
            cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, OutlineItem>(collectionView: outlineCollectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: OutlineItem) -> UICollectionViewCell? in
            // Return the cell.
            if item.subitems.isEmpty {
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            } else {
                return collectionView.dequeueConfiguredReusableCell(using: containerCellRegistration, for: indexPath, item: item)
            }
        }
        
        // load our initial data
        let snapshot = initialSnapshot()
        self.dataSource.apply(snapshot, to: .main, animatingDifferences: false)
    }
    
    func generateLayout() -> UICollectionViewLayout {
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
    
    
    func initialSnapshot() -> NSDiffableDataSourceSectionSnapshot<OutlineItem> {
        var snapshot = NSDiffableDataSourceSectionSnapshot<OutlineItem>()
        
        func addItems(_ menuItems: [OutlineItem], to parent: OutlineItem?) {
            snapshot.append(menuItems, to: parent)
            for menuItem in menuItems where !menuItem.subitems.isEmpty {
                addItems(menuItem.subitems, to: menuItem)
            }
        }
        
        addItems(menuItems, to: nil)
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
