import Foundation

public class WebAuthnRegistrationRequest: Codable, DictionaryEncodable {
    public let origin: String
    public let friendlyName: String
    public let profile: ProfileWebAuthnSignupRequest?
    public let clientId: String?
    
    public init(origin: String, friendlyName: String, profile: ProfileWebAuthnSignupRequest?,clientId: String?) {
        self.origin = origin
        self.friendlyName = friendlyName
        self.profile = profile
        self.clientId = clientId
    }
}
