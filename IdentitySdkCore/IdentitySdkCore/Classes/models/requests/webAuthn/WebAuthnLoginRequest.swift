import Foundation

public class WebAuthnLoginRequest: Codable, DictionaryEncodable {
    
    public var clientId: String
    public var origin: String
    public var email: String
    public var scope: String? = nil
    
    public init(clientId: String,origin: String,email: String, scope: String?) {
        self.clientId = clientId
        self.origin = origin
        self.email = email
        self.scope = scope
    }
}

