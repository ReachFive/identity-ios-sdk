import Foundation

public class LoginRequest: Codable, DictionaryEncodable {
    public let username: String
    public let password: String
    public let grantType: String
    public let clientId: String
    public let scope: String
    
    public init(username: String, password: String, grantType: String, clientId: String, scope: String) {
        self.username = username
        self.password = password
        self.grantType = grantType
        self.clientId = clientId
        self.scope = scope
    }
}
