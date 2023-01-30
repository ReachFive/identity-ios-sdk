import Foundation
import AuthenticationServices

public class PasskeySignupRequest {
    public let passkeyPofile: ProfilePasskeySignupRequest
    /// The name that will be displayed by the system when presenting the passkey for login
    public let friendlyName: String
    public let origin: String?
    public let scopes: [String]?
    public let anchor: ASPresentationAnchor
    
    public init(passkeyPofile: ProfilePasskeySignupRequest, friendlyName: String, anchor: ASPresentationAnchor, origin: String? = nil, scopes: [String]? = nil) {
        self.passkeyPofile = passkeyPofile
        self.friendlyName = friendlyName
        self.origin = origin
        self.scopes = scopes
        self.anchor = anchor
    }
}
