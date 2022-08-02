import Foundation

public class SignupRequest: Codable, DictionaryEncodable {
    public let clientId: String
    public let data: ProfileSignupRequest
    public let scope: String
    public let redirectUrl: String?
    
    public init(clientId: String, data: ProfileSignupRequest, scope: String, redirectUrl: String?) {
        self.clientId = clientId
        self.data = data
        self.scope = scope
        self.redirectUrl = redirectUrl
    }
}
