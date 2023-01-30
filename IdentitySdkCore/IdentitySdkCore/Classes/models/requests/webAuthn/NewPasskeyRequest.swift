import Foundation
import AuthenticationServices

public class NewPasskeyRequest {
    public let origin: String?
    public let friendlyName: String
    public let anchor: ASPresentationAnchor
    
    public init(anchor: ASPresentationAnchor, friendlyName: String, origin: String? = nil) {
        self.origin = origin
        self.friendlyName = friendlyName
        self.anchor = anchor
    }
}
