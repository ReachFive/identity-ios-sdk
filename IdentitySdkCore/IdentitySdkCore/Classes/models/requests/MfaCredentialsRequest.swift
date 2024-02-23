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
    
    public init(_ verificationCode: String) {
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
    public let verificationCode: String
    
    public init(_ verificationCode: String) {
        self.verificationCode = verificationCode
    }
}

public class MfaStartCredentialRegistrationResponse: Codable, DictionaryEncodable {
    public let status: String
    public let credential: MfaRegistrationSuccess?
    
    public init(status: String, credential: MfaRegistrationSuccess? = nil) {
        self.status = status
        self.credential = credential
    }
}

public enum Status: String {
    case emailSent = "email_sent"
    case enabled = "enabled"
    case smsSent = "sms_sent"
}

public class MfaRegistrationSuccess: Codable, DictionaryEncodable {
    public let type: String
    public let email: String?
    public let phoneNumber: String?
    public let friendlyName: String
    
    public init(type: String, friendlyName: String, email: String? = nil, phoneNumber: String? = nil) {
        self.type = type
        self.email = email
        self.phoneNumber = phoneNumber
        self.friendlyName = friendlyName
    }
}
