import BrightFutures
import Foundation
import IdentitySdkCore
import UIKit

class MfaController: UIViewController {
    @IBOutlet var phoneNumberMfaRegistration: UITextField!
    
    var listMfaCredentialsView: UICollectionView! = nil
    
    enum Section {
        case main
    }
    
    var listMfaCredentialsDataSource: UICollectionViewDiffableDataSource<Section, MfaCredential>! = nil
    
    var currentListMfaCredentialSnapshot: NSDiffableDataSourceSnapshot<Section, MfaCredential>! = nil
    
    var mfaCredentialsToDisplay: [MfaCredential] = [] {
        didSet {
            currentListMfaCredentialSnapshot.appendItems(mfaCredentialsToDisplay)
            listMfaCredentialsDataSource.apply(currentListMfaCredentialSnapshot)
        }
    }

    private func fetchMfaCredentials() {
        guard let authToken = AppDelegate.storage.getToken() else {
            print("not logged in")
            return
        }
        AppDelegate.reachfive()
            .mfaListCredentials(authToken: authToken)
            .onSuccess { response in
                self.mfaCredentialsToDisplay = response.credentials.map { MfaCredential.convert(from: $0) }
            }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureDataSource()
        fetchMfaCredentials()
    }
    
    @IBAction func startMfaPhoneRegistration(_ sender: UIButton) {
        print("MfaController.startMfaPhoneRegistration")
        guard let authToken = AppDelegate.storage.getToken() else {
            print("not logged in")
            return
        }
        guard let phoneNumber = phoneNumberMfaRegistration.text else {
            print("phone number cannot be empty")
            return
        }
        
        let mfaAction = MfaAction(presentationAnchor: self)
        mfaAction.mfaStart(registering: .PhoneNumber(phoneNumber), authToken: authToken).onSuccess { _ in
            self.fetchMfaCredentials()
        }
    }
}

class MfaAction {
    let presentationAnchor: UIViewController
    
    public init(presentationAnchor: UIViewController) {
        self.presentationAnchor = presentationAnchor
    }
    
    func mfaStart(registering credential: Credential, authToken: AuthToken) -> Future<Void, ReachFiveError> {
        let future = AppDelegate.reachfive()
            .mfaStart(registering: credential, authToken: authToken)
            .recoverWith { error in
                guard case let .AuthFailure(reason: _, apiError: apiError) = error,
                      let key = apiError?.errorMessageKey,
                      key == "error.accessToken.freshness"
                else {
                    return Future(error: error)
                }
                
                // Automatically refresh the token if it is stale
                return AppDelegate.reachfive()
                    .refreshAccessToken(authToken: authToken).flatMap { (freshToken: AuthToken) in
                        AppDelegate.storage.setToken(freshToken)
                        return AppDelegate.reachfive()
                            .mfaStart(registering: credential, authToken: freshToken)
                    }
            }
            .flatMap { resp in
                self.handleStartVerificationCode(resp)
            }
            .onFailure { error in
                let alert = AppDelegate.createAlert(title: "Start MFA \(credential.credentialType) Registration", message: "Error: \(error.message())")
                self.presentationAnchor.present(alert, animated: true)
            }
        
        return future
    }
    
    private func handleStartVerificationCode(_ resp: MfaStartRegistrationResponse) -> Future<Void, ReachFiveError> {
        let promise: Promise<Void, ReachFiveError> = Promise()
        switch resp {
        case let .Success(registeredCredential):
            let alert = AppDelegate.createAlert(title: "MFA \(registeredCredential.type) \(registeredCredential.friendlyName) enabled", message: "Success")
            presentationAnchor.present(alert, animated: true)
            promise.success(())
        
        case let .VerificationNeeded(continueRegistration):
            let canal =
                switch continueRegistration.credentialType {
                case .Email: "Email"
                case .PhoneNumber: "SMS"
                }
            
            let alert = UIAlertController(title: "Verification Code", message: "Please enter the verification Code you got by \(canal)", preferredStyle: .alert)
            alert.addTextField { textField in
                textField.placeholder = "Verification code"
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                promise.failure(.AuthCanceled)
            }
            
            let submitVerificationCode = UIAlertAction(title: "Submit", style: .default) { _ in
                guard let verificationCode = alert.textFields?[0].text, !verificationCode.isEmpty else {
                    print("verification code cannot be empty")
                    promise.failure(.AuthFailure(reason: "no verification code"))
                    return
                }
                let future = continueRegistration.verify(code: verificationCode)
                promise.completeWith(future)
                future
                    .onSuccess { _ in
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
            presentationAnchor.present(alert, animated: true)
        }
        return promise.future
    }
}

extension MfaController {
    func createLayout() -> UICollectionViewLayout {
        let sectionProvider = { (_: Int,
                                 _: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                      heightDimension: .fractionalHeight(0.1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                    
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.85),
                                                       heightDimension: .absolute(250))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)

                let titleSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .estimated(22))
                let titleSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: titleSize,
                    elementKind: "Mfa credentials",
                    alignment: .top)
                titleSupplementary.pinToVisibleBounds = true
                section.boundarySupplementaryItems = [titleSupplementary]
                return section
        }

        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 20

        let layout = UICollectionViewCompositionalLayout(
            sectionProvider: sectionProvider, configuration: config)
        return layout
    }
    
    func configureHierarchy() {
        listMfaCredentialsView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        listMfaCredentialsView?.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(listMfaCredentialsView)
        NSLayoutConstraint.activate([
            listMfaCredentialsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            listMfaCredentialsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            listMfaCredentialsView.topAnchor.constraint(equalTo: view.topAnchor, constant: view.frame.height/2),
            listMfaCredentialsView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<CredentialCollectionViewCell, MfaCredential> { cell, _, credential in
            cell.configure(with: credential)
        }
        listMfaCredentialsDataSource = UICollectionViewDiffableDataSource<Section, MfaCredential>(collectionView: listMfaCredentialsView) {
            (collectionView: UICollectionView, indexPath: IndexPath, credential: MfaCredential) -> UICollectionViewCell? in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: credential)
        }
        let supplementaryRegistration = UICollectionView.SupplementaryRegistration
        <TitleSupplementaryView>(elementKind: "Mfa credentials") {
            (supplementaryView, _, _) in
            supplementaryView.label.text = "Enrolled MFA credentials"
        }
        
        listMfaCredentialsDataSource.supplementaryViewProvider = { _, _, index in
            self.listMfaCredentialsView.collectionViewLayout.collectionView?.dequeueConfiguredReusableSupplementary(
                using: supplementaryRegistration, for: index)
        }
        currentListMfaCredentialSnapshot = NSDiffableDataSourceSnapshot
        <Section, MfaCredential>()
        currentListMfaCredentialSnapshot.appendSections([.main])
        currentListMfaCredentialSnapshot.appendItems(mfaCredentialsToDisplay)
        listMfaCredentialsDataSource.apply(currentListMfaCredentialSnapshot, animatingDifferences: false)
    }
}

class CredentialCollectionViewCell: UICollectionViewListCell {
    static let identifier = "CredentialCollectionViewCell"

    let id: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        
        return label
    }()
    
    let createdAt: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)

        return label
    }()
}

extension CredentialCollectionViewCell {
    public func configure(with credential: MfaCredential) {
        id.text = credential.identifier
        createdAt.text = credential.createdAt
        id.translatesAutoresizingMaskIntoConstraints = false
        createdAt.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(id)
        contentView.addSubview(createdAt)

        let fontSize = contentView.frame.size.width < 330 ? 12.0 : 15.0
        id.font = UIFont.preferredFont(forTextStyle: .body).withSize(fontSize)
        createdAt.font = UIFont.preferredFont(forTextStyle: .body).withSize(fontSize)

        let spacing = CGFloat(contentView.frame.width/12)
    
        NSLayoutConstraint.activate([
            id.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            createdAt.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: spacing)
        ])
    }
}

struct MfaCredential: Hashable {
    let identifier: String
    let createdAt: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    static func convert(from mfaCredentialItem: MfaCredentialItem) -> MfaCredential {
        let identifier = switch mfaCredentialItem.type {
        case .sms:
            mfaCredentialItem.phoneNumber
        case .email:
            mfaCredentialItem.email
        }
        return MfaCredential(identifier: identifier!, createdAt: mfaCredentialItem.createdAt)
    }
}

class TitleSupplementaryView: UICollectionReusableView {
    let label = UILabel()
    static let reuseIdentifier = "title-supplementary-reuse-identifier"

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
}

extension TitleSupplementaryView {
    func configure() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        let inset = CGFloat(10)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            label.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset)
        ])
        label.font = UIFont.preferredFont(forTextStyle: .title3)
    }
}
