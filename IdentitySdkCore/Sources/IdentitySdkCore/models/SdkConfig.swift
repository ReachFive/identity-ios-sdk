import Foundation

public class SdkConfig {
    public let domain: String
    public let clientId: String
    public let scheme: String
    
    public init(domain: String, clientId: String, scheme: String) {
        self.domain = domain
        self.clientId = clientId
        self.scheme = scheme
    }
}
