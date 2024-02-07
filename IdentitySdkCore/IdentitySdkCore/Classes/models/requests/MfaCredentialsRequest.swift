import Foundation

public class MfaStartEmailRegistrationRequest: Codable, DictionaryEncodable {
    public let redirectUrl: String?
    
    public init(redirectUrl: String? = nil) {
            self.redirectUrl = redirectUrl
        }
}

public class MfaStartPhoneRegistrationRequest: Codable, DictionaryEncodable {
    public let phoneNumber: String
    public init(phoneNumber: String) {
            self.phoneNumber = phoneNumber
        }
}

public class MfaVerifyEmailRegistrationPostRequest: Codable, DictionaryEncodable {
    public let verificationCode: String
    
    public init(verificationCode: String) {
        self.verificationCode = verificationCode
    }
}

public class MfaVerifyEmailRegistrationGetRequest: Codable, DictionaryEncodable {
    public let c: String
    public let t: String
    
    public init(c: String, t: String) {
        self.c = c
        self.t = t
    }
}
public class MfaVerifyPhoneRegistrationRequest: Codable, DictionaryEncodable {
    public let phoneNumber: String
    public let verificationCode: String
    
    public init(phoneNumber: String, verificationCode: String) {
        self.phoneNumber = phoneNumber
        self.verificationCode = verificationCode
    }
}
