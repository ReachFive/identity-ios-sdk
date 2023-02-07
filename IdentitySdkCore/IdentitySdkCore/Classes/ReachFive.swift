import Foundation

enum State {
    case NotInitialized
    case Initialized
}

public typealias PasswordlessCallback = (_ result: Result<AuthToken, ReachFiveError>) -> Void

//TODO
// Tester One-tap account upgrade : https://developer.apple.com/videos/play/wwdc2020/10666/
// Tester le MFA avec "Securing Logins with iCloud Keychain Verification Codes" https://developer.apple.com/documentation/authenticationservices/securing_logins_with_icloud_keychain_verification_codes
// Apparemment les custom scheme sont dépréciés et il faudrait utiliser les "Universal Links" : https://developer.apple.com/ios/universal-links/
// Apparemment il faut faire du dev pour partager des credentials entre Safari et une app (app-site association ne suffit pas) : https://developer.apple.com/documentation/security/shared_web_credentials
/// ReachFive identity SDK
public class ReachFive: NSObject {
    var passwordlessCallback: PasswordlessCallback? = nil
    var state: State = .NotInitialized
    let sdkConfig: SdkConfig
    let providersCreators: Array<ProviderCreator>
    let reachFiveApi: ReachFiveApi
    var providers: [Provider] = []
    internal var scope: [String] = []
    internal let storage: Storage
    let credentialManager: CredentialManager
    
    public init(sdkConfig: SdkConfig, providersCreators: Array<ProviderCreator>, storage: Storage?) {
        self.sdkConfig = sdkConfig
        self.providersCreators = providersCreators
        self.reachFiveApi = ReachFiveApi(sdkConfig: sdkConfig)
        self.storage = storage ?? UserDefaultsStorage()
        self.credentialManager = CredentialManager(reachFiveApi: reachFiveApi)
    }
    
    public override var description: String {
        """
        Config: domain=\(sdkConfig.domain), clientId=\(sdkConfig.clientId)
        Providers: \(providers)
        Scope: \(scope.joined(separator: " "))
        """
    }
}
