import Foundation
import BrightFutures
import Alamofire

public enum CredentialType {
    case Email
    case PhoneNumber
}

public enum Credential {
    case Email(redirectUrl: String? = nil)
    case PhoneNumber(_ phoneNumber: String)
    
    var credentialType: CredentialType {
        switch self {
        case .Email: return CredentialType.Email
        case .PhoneNumber: return CredentialType.PhoneNumber
        }
    }

}

public class ContinueRegistration {
    public let credentialType: CredentialType
    private let verifyCallback: (CredentialType, String, AuthToken) -> Future<(), ReachFiveError>
    private let authToken: AuthToken
        
    fileprivate init(credentialType: CredentialType, verifyCallback: @escaping (CredentialType, String, AuthToken) -> Future<(), ReachFiveError>, authToken: AuthToken) {
        self.credentialType = credentialType
        self.authToken = authToken
        self.verifyCallback = verifyCallback
    }
        
    public func verify(code: String, freshAuthToken: AuthToken? = nil) -> Future<(), ReachFiveError> {
        self.verifyCallback(credentialType, code, freshAuthToken ?? authToken)
    }
}

public enum MfaStartRegistrationResponse {
    case Success(_ success: MfaRegistrationSuccess)
    case VerificationNeeded(_ continueRegistration: ContinueRegistration)
}

// TODO: Add an mfaStart with stepup argument label to distinguish from mfaStart registration
public extension ReachFive {
    func addMfaCredentialRegistrationCallback(mfaCredentialRegistrationCallback: @escaping MfaCredentialRegistrationCallback) {
        self.mfaCredentialRegistrationCallback = mfaCredentialRegistrationCallback
    }
    
    func mfaStart(registering credential: Credential, authToken: AuthToken) -> Future<MfaStartRegistrationResponse, ReachFiveError> {
        switch credential {
         case let Credential.Email(redirectUrl):
             let mfaStartEmailRegistrationRequest = MfaStartEmailRegistrationRequest(redirectUrl: redirectUrl ?? sdkConfig.mfaUri)
             return reachFiveApi.startMfaEmailRegistration(mfaStartEmailRegistrationRequest, authToken: authToken).map { resp in
                 switch resp.status {
                 case "enabled": return MfaStartRegistrationResponse.Success(resp.credential!)
                 default: return MfaStartRegistrationResponse.VerificationNeeded(ContinueRegistration(credentialType: credential.credentialType, verifyCallback: self.mfaVerify, authToken: authToken))
                 }
                 
             }
         case let Credential.PhoneNumber(phoneNumber):
             let mfaStartPhoneRegistrationRequest = MfaStartPhoneRegistrationRequest(phoneNumber: phoneNumber)
             return reachFiveApi.startMfaPhoneRegistration(mfaStartPhoneRegistrationRequest, authToken: authToken).map { resp in
                 switch resp.status {
                 case "enabled": return MfaStartRegistrationResponse.Success(resp.credential!)
                 default: return MfaStartRegistrationResponse.VerificationNeeded(ContinueRegistration(credentialType: credential.credentialType, verifyCallback: self.mfaVerify, authToken: authToken))
                 }
             }
         }
    }
    
    func mfaVerify(_ credentialType: CredentialType, code: String, authToken: AuthToken) -> Future<(), ReachFiveError> {
        switch credentialType {
        case .Email:
            let request = MfaVerifyEmailRegistrationPostRequest(code)
            return reachFiveApi.verifyMfaEmailRegistrationPost(request, authToken: authToken)
        case .PhoneNumber:
            let request = MfaVerifyPhoneRegistrationRequest(code)
            return reachFiveApi.verifyMfaPhoneRegistration(request, authToken: authToken)
        }
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
