import Foundation

public class WebauthnSignupCredential: Codable, DictionaryEncodable {
    public var webauthnId: String
    public var publicKeyCredential: RegistrationPublicKeyCredential
    public var originR5: String?
    
    public init(webauthnId: String, publicKeyCredential: RegistrationPublicKeyCredential, originR5: String? = nil) {
        self.webauthnId = webauthnId
        self.publicKeyCredential = publicKeyCredential
        self.originR5 = originR5
    }
}

