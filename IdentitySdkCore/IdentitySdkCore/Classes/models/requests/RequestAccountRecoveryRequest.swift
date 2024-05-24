import Foundation

/*
public enum UpdatePasswordParams {
    case EmailParams(email: String, verificationCode: String, password: String)
    case SmsParams(phoneNumber: String, verificationCode: String, password: String)
    
    public func getAuthToken() -> AuthToken? {
        switch self {
        case .FreshAccessTokenParams(let authToken, _):
            return authToken
        case .AccessTokenParams(let authToken, _, _):
            return authToken
        default:
            return nil
        }
    }
}
*/

public class RequestAccountRecoveryRequest: Codable, DictionaryEncodable {
    public let clientId: String
    public let email: String?
    public let phoneNumber: String?
    public let redirectUrl: String?
    
    public init(clientId: String, email: String?, phoneNumber: String?, redirectUrl: String?) {
        self.clientId = clientId
        self.email = email
        self.phoneNumber = phoneNumber
        self.redirectUrl = redirectUrl
    }
}

/*
public class UpdatePasswordRequest: Codable, DictionaryEncodable {
    let clientId: String?
    let password: String?
    let oldPassword: String?
    let email: String?
    let phoneNumber: String?
    let verificationCode: String?
    
    public init(
        clientId: String? = nil,
        password: String? = nil,
        oldPassword: String? = nil,
        email: String? = nil,
        phoneNumber: String? = nil,
        verificationCode: String? = nil
    ) {
        self.clientId = clientId
        self.password = password
        self.oldPassword = oldPassword
        self.email = email
        self.phoneNumber = phoneNumber
        self.verificationCode = verificationCode
    }
    
    public convenience init(updatePasswordParams: UpdatePasswordParams, sdkConfig: SdkConfig) {
        switch updatePasswordParams {
        case .FreshAccessTokenParams(_, let password):
            self.init(password: password)
        case .AccessTokenParams(_, let password, let oldPassword):
            self.init(password: password, oldPassword: oldPassword)
        case .EmailParams(let email, let verificationCode, let password):
            self.init(clientId: sdkConfig.clientId, password: password, email: email, verificationCode: verificationCode)
        case .SmsParams(let phoneNumber, let verificationCode, let password):
            self.init(clientId: sdkConfig.clientId, password: password, phoneNumber: phoneNumber, verificationCode: verificationCode)
        }
    }
}*/
