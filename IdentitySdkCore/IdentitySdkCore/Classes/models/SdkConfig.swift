import Foundation

public class SdkConfig {
    public let domain: String
    public let clientId: String
    
    /// Alias for the `redirectUri`
    public let scheme: String
    
    ///The scheme of the form `reachfive-clientId`
    public let baseScheme: String
    /// The redirect URI of the form `reachfive-clientId://callback`
    public let redirectUri: String
    /// The redirect URI for MFA of the form `reachfive-clientId://mfa`
    public let mfaUri: String
    
    public init(domain: String, clientId: String, scheme: String? = nil, baseScheme: String? = nil, mfaUri: String? = nil) {
          self.domain = domain
          self.clientId = clientId
          self.baseScheme = baseScheme ?? "reachfive-\(clientId)"
          self.scheme = scheme ?? "\(self.baseScheme)://callback"
          self.redirectUri = self.scheme
          self.mfaUri = mfaUri ?? "\(self.baseScheme)://mfa"
      }
}
