import Foundation

public class LoginRequest: Codable, DictionaryEncodable {
    public let email: String?
    public let phoneNumber: String?
    public let password: String
    public let grantType: String
    public let clientId: String
    public let scope: String
    
    public init(email: String?, phoneNumber: String?, password: String, grantType: String, clientId: String, scope: String) {
        self.email = email
        self.phoneNumber = phoneNumber
        self.password = password
        self.grantType = grantType
        self.clientId = clientId
        self.scope = scope
    }
}
