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
    
    public var credentialType: CredentialType {
        switch self {
        case .Email: return CredentialType.Email
        case .PhoneNumber: return CredentialType.PhoneNumber
        }
    }
}

public class ContinueRegistration {
    public let credentialType: CredentialType
    private let reachfive: ReachFive
    private let authToken: AuthToken
    
    fileprivate init(credentialType: CredentialType, reachfive: ReachFive, authToken: AuthToken) {
        self.credentialType = credentialType
        self.authToken = authToken
        self.reachfive = reachfive
    }
    
    public func verify(code: String, freshAuthToken: AuthToken? = nil) -> Future<(), ReachFiveError> {
        reachfive.mfaVerify(credentialType, code: code, authToken: freshAuthToken ?? authToken)
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
        let registration =
        switch credential {
        case let .Email(redirectUrl):
            reachFiveApi.startMfaEmailRegistration(MfaStartEmailRegistrationRequest(redirectUrl: redirectUrl ?? sdkConfig.mfaUri), authToken: authToken)
        case let .PhoneNumber(phoneNumber):
            reachFiveApi.startMfaPhoneRegistration(MfaStartPhoneRegistrationRequest(phoneNumber: phoneNumber), authToken: authToken)
        }
        
        return registration.map { resp in
            switch resp.status {
            case "enabled":  .Success(resp.credential!)
            default:  .VerificationNeeded(ContinueRegistration(credentialType: credential.credentialType, reachfive: self, authToken: authToken))
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
        
        if let error = params?.first(where: { $0.name == "error" })?.value {
            mfaCredentialRegistrationCallback?(.failure(.TechnicalError(reason: error, apiError: ApiError(fromQueryParams: params))))
            return
        }
        
        self.mfaCredentialRegistrationCallback?(.success(()))
    }
}
