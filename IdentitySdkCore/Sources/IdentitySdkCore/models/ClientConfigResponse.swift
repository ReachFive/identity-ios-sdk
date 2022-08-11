import Foundation

public class ClientConfigResponse: Codable {
    public let scope: String
    
    public init(scope: String) {
        self.scope = scope
    }
}
