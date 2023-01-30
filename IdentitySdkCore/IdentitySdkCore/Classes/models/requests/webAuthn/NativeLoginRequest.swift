import Foundation
import AuthenticationServices

public class NativeLoginRequest {
    public let origin: String?
    public let scopes: [String]?
    public let anchor: ASPresentationAnchor
    
    public init(anchor: ASPresentationAnchor, origin: String? = nil, scopes: [String]? = nil) {
        self.origin = origin
        self.scopes = scopes
        self.anchor = anchor
    }
}
