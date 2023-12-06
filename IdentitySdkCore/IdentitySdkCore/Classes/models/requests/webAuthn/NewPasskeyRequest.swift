import Foundation
import AuthenticationServices

public class NewPasskeyRequest {
    public let originWebAuthn: String?
    /// The name that will be displayed by the system when presenting the passkey for login
    public let friendlyName: String
    public let anchor: ASPresentationAnchor
    
    public init(anchor: ASPresentationAnchor, friendlyName: String, originWebAuthn: String? = nil) {
        self.originWebAuthn = originWebAuthn
        self.friendlyName = friendlyName
        self.anchor = anchor
    }
}
