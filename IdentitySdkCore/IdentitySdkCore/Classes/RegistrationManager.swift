import Foundation
import AuthenticationServices
import BrightFutures

public class RegistrationManager: NSObject {
    let reachFiveApi: ReachFiveApi
    
    // MARK: - these fields serve to remember the context between the start of a request and its completion
    // No need to erase them at the end of a request (though it mightbe useful to release the associated memory)
    
    // promise for new key registration
    var promise: Promise<(), ReachFiveError>
    
    // anchor for presentationContextProvider
    var authenticationAnchor: ASPresentationAnchor?
    
    var authToken: AuthToken?
    
    // MARK: -
    
    public init(reachFiveApi: ReachFiveApi) {
        promise = Promise()
        self.reachFiveApi = reachFiveApi
    }
    
    @available(iOS 16.0, *)
    func registerNewPasskey(withRequest request: NewPasskeyRequest, authToken: AuthToken) -> Future<(), ReachFiveError> {
        promise = Promise()
        authenticationAnchor = request.anchor
        
        reachFiveApi.createWebAuthnRegistrationOptions(authToken: authToken, registrationRequest: RegistrationRequest(origin: request.origin!, friendlyName: request.friendlyName))
            .flatMap { options -> Result<ASAuthorizationRequest, ReachFiveError> in
                self.authToken = authToken
                
                guard let challenge = options.options.publicKey.challenge.decodeBase64Url() else {
                    return .failure(.TechnicalError(reason: "unreadable challenge: \(options.options.publicKey.challenge)"))
                }
                
                guard let userID = options.options.publicKey.user.id.decodeBase64Url() else {
                    return .failure(.TechnicalError(reason: "unreadable userID from public key: \(options.options.publicKey.user.id)"))
                }
                
                let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: self.reachFiveApi.sdkConfig.domain)
                return .success(publicKeyCredentialProvider.createCredentialRegistrationRequest(challenge: challenge, name: request.friendlyName, userID: userID))
            }
            .onSuccess { registrationRequest in
                let authController = ASAuthorizationController(authorizationRequests: [registrationRequest])
                authController.delegate = self
                authController.presentationContextProvider = self
                authController.performRequests()
            }
            .onFailure { error in self.promise.failure(error) }
        
        return promise.future
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension RegistrationManager: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        authenticationAnchor!
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension RegistrationManager: ASAuthorizationControllerDelegate {
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        if #available(iOS 16.0, *), let credentialRegistration = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
            // A new passkey was registered
            guard let attestationObject = credentialRegistration.rawAttestationObject else {
                promise.tryFailure(.TechnicalError(reason: "didCompleteWithAuthorization: no attestationObject"))
                return
            }
            
            let clientDataJSON = credentialRegistration.rawClientDataJSON
            let r5AuthenticatorAttestationResponse = R5AuthenticatorAttestationResponse(attestationObject: attestationObject.toBase64Url(), clientDataJSON: clientDataJSON.toBase64Url())
            
            let id = credentialRegistration.credentialID.toBase64Url()
            let registrationPublicKeyCredential = RegistrationPublicKeyCredential(id: id, rawId: id, type: "public-key", response: r5AuthenticatorAttestationResponse)
            guard let authToken else {
                promise.tryFailure(.TechnicalError(reason: "didCompleteWithAuthorization: no token"))
                return
            }
            
            promise.completeWith(reachFiveApi.registerWithWebAuthn(authToken: authToken, publicKeyCredential: registrationPublicKeyCredential))
        } else {
            promise.tryFailure(.TechnicalError(reason: "didCompleteWithAuthorization: Received unknown authorization type."))
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        promise.tryFailure(.TechnicalError(reason: "\(error)"))
    }
}
