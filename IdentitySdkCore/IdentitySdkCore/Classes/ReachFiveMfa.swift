import Foundation
import BrightFutures
import Alamofire

public enum CredentialVerification {
    case Email
    case SMS
}

public enum Credential {
    case Email(redirectUrl: String? = nil)
    case PhoneNumber(_ phoneNumber: String)
}

public extension ReachFive {
    
    func addMfaCredentialRegistrationCallback(mfaCredentialRegistrationCallback: @escaping MfaCredentialRegistrationCallback) {
        self.mfaCredentialRegistrationCallback = mfaCredentialRegistrationCallback
    }
    
    func mfaStartRegistering(credential: Credential, authToken: AuthToken) -> Future<MfaStartCredentialRegistrationResponse, ReachFiveError> {
        switch credential {
        case let .Email(redirectUrl):
            let mfaStartEmailRegistrationRequest = MfaStartEmailRegistrationRequest(redirectUrl: redirectUrl ?? sdkConfig.scheme)
            return reachFiveApi.startMfaEmailRegistration(authToken: authToken, mfaStartEmailRegistrationRequest: mfaStartEmailRegistrationRequest)
        case let .PhoneNumber(phoneNumber):
            let mfaStartPhoneRegistrationRequest = MfaStartPhoneRegistrationRequest(phoneNumber: phoneNumber)
            return reachFiveApi.startMfaPhoneRegistration(authToken: authToken, mfaStartPhoneRegistrationRequest: mfaStartPhoneRegistrationRequest)
        }
    }
    
    func mfaVerifyRegistering(credential: CredentialVerification, verificationCode: String, authToken: AuthToken) -> Future<(), ReachFiveError> {
        switch credential {
        case .Email:
            let mfaVerifyEmailRegistrationRequest = MfaVerifyEmailRegistrationPostRequest(verificationCode: verificationCode)
            return reachFiveApi.verifyMfaEmailRegistrationPost(authToken: authToken, mfaVerifyEmailRegistrationRequest: mfaVerifyEmailRegistrationRequest)
        case .SMS:
            let mfaVerifyPhoneRegistrationRequest = MfaVerifyPhoneRegistrationRequest(verificationCode: verificationCode)
            return reachFiveApi.verifyMfaPhoneRegistration(authToken: authToken, mfaVerifyPhoneRegistrationRequest: mfaVerifyPhoneRegistrationRequest)
        }
    }
    
    internal func verifyMfaEmailGetRegistration(verificationCode: String, magicLink: String) -> Future<(), ReachFiveError> {
        let mfaVerifyEmailRegistrationGetRequest = MfaVerifyEmailRegistrationGetRequest(c: verificationCode, t: magicLink)
        return reachFiveApi.verifyMfaEmailRegistrationGet(request: mfaVerifyEmailRegistrationGetRequest)
    }
    
    internal func interceptVerifyMfaCredential(_ url: URL) {
        let params = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems
        
        if let error = params?.first(where: { $0.name == "error"})?.value {
            mfaCredentialRegistrationCallback?(.failure(.TechnicalError(reason: error, apiError: ApiError(fromQueryParams: params))))
            return
        }
        
        self.mfaCredentialRegistrationCallback?(.success(()))
    }
}
