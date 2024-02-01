import Foundation
import BrightFutures

public enum StartMfaCredentialRegistrationRequest {
    case Email(redirectUrl: String?)
    case PhoneNumber(phoneNumber: String)
}

public enum VerifyMfaCredentialRegistrationRequest {
    case Email(verificationCode: String)
    case PhoneNumber(verificationCode: String, phoneNumber: String)
}

public extension ReachFive {
    func startMfaCredentialRegistration(authToken: AuthToken, request: StartMfaCredentialRegistrationRequest) -> Future<(), ReachFiveError> {
        switch request {
        case let .Email(redirectUrl):
            let mfaStartEmailRegistrationRequest = MfaStartEmailRegistrationRequest(redirectUrl: redirectUrl)
            return reachFiveApi.startMfaEmailRegistration(authToken: authToken, mfaStartEmailRegistrationRequest: mfaStartEmailRegistrationRequest)
        case let .PhoneNumber(phoneNumber):
            let mfaStartPhoneRegistrationRequest = MfaStartPhoneRegistrationRequest(phoneNumber: phoneNumber)
            return reachFiveApi.startMfaPhoneRegistration(authToken: authToken, mfaStartPhoneRegistrationRequest: mfaStartPhoneRegistrationRequest)
        }
    }
    
    func verifyMfaCredentialRegistration(authToken: AuthToken, request: VerifyMfaCredentialRegistrationRequest) -> Future<(), ReachFiveError> {
        switch request {
        case let .Email(verificationCode):
            let mfaVerifyEmailRegistrationRequest = MfaVerifyEmailRegistrationRequest(verificationCode: verificationCode)
            return reachFiveApi.verifyMfaEmailRegistration(authToken: authToken, mfaVerifyEmailRegistrationRequest: mfaVerifyEmailRegistrationRequest)
        case let .PhoneNumber(verificationCode, phoneNumber):
            let mfaVerifyPhoneRegistrationRequest = MfaVerifyPhoneRegistrationRequest(phoneNumber: phoneNumber, verificationCode: verificationCode)
            return reachFiveApi.verifyMfaPhoneRegistration(authToken: authToken, mfaVerifyPhoneRegistrationRequest: mfaVerifyPhoneRegistrationRequest)
        }
    }
    
}
