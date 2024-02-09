import Foundation
import BrightFutures
import Alamofire

public enum StartMfaCredentialRegistrationRequest {
    case Email(redirectUrl: String?)
    case PhoneNumber(phoneNumber: String)
}

public enum VerifyMfaCredentialRegistrationRequest {
    case Email(verificationCode: String)
    case PhoneNumber(verificationCode: String, phoneNumber: String)
}

public extension ReachFive {
    
    func addMfaCredentialRegistrationCallback(mfaCredentialRegistrationCallback: @escaping MfaCredentialRegistrationCallback) {
        self.mfaCredentialRegistrationCallback = mfaCredentialRegistrationCallback
    }
    
    func startMfaCredentialRegistration(authToken: AuthToken, request: StartMfaCredentialRegistrationRequest) -> Future<MfaStartCredentialRegistrationResponse, ReachFiveError> {
        switch request {
        case let .Email(redirectUrl):
            let mfaStartEmailRegistrationRequest = MfaStartEmailRegistrationRequest(redirectUrl: redirectUrl ?? sdkConfig.scheme)
            return reachFiveApi.startMfaEmailRegistration(authToken: authToken, mfaStartEmailRegistrationRequest: mfaStartEmailRegistrationRequest)
        case let .PhoneNumber(phoneNumber):
            let mfaStartPhoneRegistrationRequest = MfaStartPhoneRegistrationRequest(phoneNumber: phoneNumber)
            return reachFiveApi.startMfaPhoneRegistration(authToken: authToken, mfaStartPhoneRegistrationRequest: mfaStartPhoneRegistrationRequest)
        }
    }
    
    func verifyMfaCredentialRegistration(authToken: AuthToken, request: VerifyMfaCredentialRegistrationRequest, httpMethod: HTTPMethod = .post) -> Future<(), ReachFiveError> {
        switch request {
        case let .Email(verificationCode):
            let mfaVerifyEmailRegistrationRequest = MfaVerifyEmailRegistrationPostRequest(verificationCode: verificationCode)
            return reachFiveApi.verifyMfaEmailRegistrationPost(authToken: authToken, mfaVerifyEmailRegistrationRequest: mfaVerifyEmailRegistrationRequest)
        case let .PhoneNumber(verificationCode, phoneNumber):
            let mfaVerifyPhoneRegistrationRequest = MfaVerifyPhoneRegistrationRequest(phoneNumber: phoneNumber, verificationCode: verificationCode)
            return reachFiveApi.verifyMfaPhoneRegistration(authToken: authToken, mfaVerifyPhoneRegistrationRequest: mfaVerifyPhoneRegistrationRequest)
        }
    }
    
    internal func verifyMfaEmailGetRegistration(verificationCode: String, magicLink: String) -> Future<(), ReachFiveError> {
        let mfaVerifyEmailRegistrationGetRequest = MfaVerifyEmailRegistrationGetRequest(c: verificationCode, t: magicLink)
        return reachFiveApi.verifyMfaEmailRegistrationGet(request: mfaVerifyEmailRegistrationGetRequest)
    }
    
    internal func interceptVerifyMfaCredential(_ url: URL) {
        let params = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems
        
        let error = params?.first(where: { $0.name == "error"})
        guard error?.name == nil else {
            mfaCredentialRegistrationCallback?(.failure(.TechnicalError(reason: error?.name ?? "", apiError: ApiError(fromQueryParams: params))))
            return
        }
        self.mfaCredentialRegistrationCallback?(.success(()))
    }
}
