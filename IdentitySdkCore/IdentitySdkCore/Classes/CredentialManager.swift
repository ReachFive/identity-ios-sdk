import Foundation
import AuthenticationServices
import BrightFutures

public class CredentialManager: NSObject {
    // promise for authentification
    var promise: Promise<AuthenticationToken, ReachFiveError>
    // promise for new key registration
    var registrationPromise: Promise<(), ReachFiveError>
    let reachFiveApi: ReachFiveApi
    
    // anchor for presentationContextProvider
    var authenticationAnchor: ASPresentationAnchor?
    // the controller for the current request, to cancel it before starting a new request (mainly to cancel AutoFillAssistedRequests when starting modal requests)
    var authController: ASAuthorizationController?
    
    // Below are three fields that should be memorized between performRequests and didCompleteWithAuthorization
    
    // indicates whether the query is modal or inline, in order to show a special error when the modal is canceled by the user
    var isPerformingModalReqest = false
    // indicates whether the request is a signup or for a new passkey
    var signupOrAddPasskey: SignupOrAddPasskey?
    // the scope when logging in with a password
    var scope: String?
    
    enum SignupOrAddPasskey {
        case Signup(signupOptions: RegistrationOptions)
        case AddPasskey(authToken: AuthToken)
    }
    
    public init(reachFiveApi: ReachFiveApi) {
        promise = Promise()
        registrationPromise = Promise()
        self.reachFiveApi = reachFiveApi
    }
    
    @available(iOS 16.0, *)
    func signUp(withRequest request: SignupOptions, anchor: ASPresentationAnchor) -> Future<AuthenticationToken, ReachFiveError> {
        authController?.cancel()
        promise = Promise()
        authenticationAnchor = anchor
        
        reachFiveApi.createWebAuthnSignupOptions(webAuthnSignupOptions: request)
            .flatMap { options -> Result<ASAuthorizationRequest, ReachFiveError> in
                self.signupOrAddPasskey = .Signup(signupOptions: options)
                
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
                
                self.authController = authController
                self.isPerformingModalReqest = true
            }
            .onFailure { error in self.promise.failure(error) }
        
        return promise.future
    }
    
    @available(iOS 16.0, *)
    func registerNewPasskey(withRequest request: NewPasskeyRequest, authToken: AuthToken) -> Future<(), ReachFiveError> {
        authController?.cancel()
        registrationPromise = Promise()
        authenticationAnchor = request.anchor
        
        reachFiveApi.createWebAuthnRegistrationOptions(authToken: authToken, registrationRequest: RegistrationRequest(origin: request.origin!, friendlyName: request.friendlyName))
            .flatMap { options -> Result<ASAuthorizationRequest, ReachFiveError> in
                self.signupOrAddPasskey = .AddPasskey(authToken: authToken)
                
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
                
                self.authController = authController
                self.isPerformingModalReqest = true
            }
            .onFailure { error in self.registrationPromise.failure(error) }
        
        return registrationPromise.future
    }
    
    @available(macCatalyst, unavailable)
    @available(iOS 16.0, *)
    func beginAutoFillAssistedPasskeySignIn(request: NativeLoginRequest) -> Future<AuthenticationToken, ReachFiveError> {
        authController?.cancel()
        promise = Promise()
        authenticationAnchor = request.anchor
        
        let webAuthnLoginRequest = WebAuthnLoginRequest(clientId: reachFiveApi.sdkConfig.clientId, origin: request.origin!, scope: request.scopes)
        
        reachFiveApi.createWebAuthnAuthenticationOptions(webAuthnLoginRequest: webAuthnLoginRequest)
            .flatMap(createCredentialAssertionRequest)
            .onSuccess { authorizationRequest in
                
                // AutoFill-assisted requests only support ASAuthorizationPlatformPublicKeyCredentialAssertionRequest.
                let authController = ASAuthorizationController(authorizationRequests: [authorizationRequest])
                authController.delegate = self
                authController.presentationContextProvider = self
                authController.performAutoFillAssistedRequests()
                self.authController = authController
                self.isPerformingModalReqest = false
            }
            .onFailure { error in self.promise.failure(error) }
        
        return promise.future
    }
    
    func login(withNonDiscoverableUsername username: Username, forRequest request: NativeLoginRequest, usingModalAuthorizationFor requestTypes: [NonDiscoverableAuthorization], display mode: Mode) -> Future<AuthenticationToken, ReachFiveError> {
        if #available(iOS 16.0, *) { authController?.cancel() }
        promise = Promise()
        authenticationAnchor = request.anchor
        
        let webAuthnLoginRequest = WebAuthnLoginRequest(clientId: reachFiveApi.sdkConfig.clientId, origin: request.origin!, scope: request.scopes)
        switch username {
        
        case .Unspecified(username: let username):
            if username.contains("@") {
                webAuthnLoginRequest.email = username
            } else {
                webAuthnLoginRequest.phoneNumber = username
            }
        case .Email(email: let email):
            webAuthnLoginRequest.email = email
        case .PhoneNumber(phoneNumber: let phoneNumber):
            webAuthnLoginRequest.phoneNumber = phoneNumber
        }
        
        let authzs = requestTypes.compactMap { adaptAuthz($0) }
        
        return signInWith(webAuthnLoginRequest, withMode: mode, authorizing: authzs) { assertionRequestOptions in
            guard #available(iOS 16.0, *) else { // can't happen, because this is called from a >= iOS 16 context
                return .success(nil)
            }
            return self.createCredentialAssertionRequest(assertionRequestOptions)
                .flatMap { assertionRequest -> Result<ASAuthorizationRequest, ReachFiveError> in
                    
                    guard let allowedCredentials = assertionRequestOptions.publicKey.allowCredentials else {
                        return .failure(.AuthFailure(reason: "no allowCredentials returned"))
                    }
                    
                    let credentialIDs = allowedCredentials.compactMap { $0.id.decodeBase64Url() }
                    assertionRequest.allowedCredentials = credentialIDs.map(ASAuthorizationPlatformPublicKeyCredentialDescriptor.init(credentialID:))
                    
                    return .success(assertionRequest)
                }
                .map { $0 }
        }
    }
    
    func login(withRequest request: NativeLoginRequest, usingModalAuthorizationFor requestTypes: [ModalAuthorization], display mode: Mode) -> Future<AuthenticationToken, ReachFiveError> {
        if #available(iOS 16.0, *) { authController?.cancel() }
        promise = Promise()
        authenticationAnchor = request.anchor
        
        scope = (request.scopes ?? []).joined(separator: " ")
        
        let webAuthnLoginRequest = WebAuthnLoginRequest(clientId: reachFiveApi.sdkConfig.clientId, origin: request.origin!, scope: request.scopes)
        
        return signInWith(webAuthnLoginRequest, withMode: mode, authorizing: requestTypes) { authenticationOptions in
            guard #available(iOS 16.0, *) else { // can't happen, because this is called from a >= iOS 15 context
                return .success(nil)
            }
            return self.createCredentialAssertionRequest(authenticationOptions).map { $0 }
        }
    }
    
    private func signInWith(_ webAuthnLoginRequest: WebAuthnLoginRequest, withMode mode: Mode, authorizing requestTypes: [ModalAuthorization], makeAuthorization: @escaping (AuthenticationOptions) -> Result<ASAuthorizationRequest?, ReachFiveError>) -> Future<AuthenticationToken, ReachFiveError> {
        
        requestTypes.traverse { type -> Future<ASAuthorizationRequest?, ReachFiveError> in
                switch type {
                
                case .Password:
                    // Allow the user to use a saved password, if they have one.
                    let passwordRequest = ASAuthorizationPasswordProvider().createRequest()
                    return Future(value: passwordRequest)
                
                case .Passkey:
                    // Allow the user to use a saved passkey, if they have one.
                    return reachFiveApi.createWebAuthnAuthenticationOptions(webAuthnLoginRequest: webAuthnLoginRequest)
                        .flatMap { makeAuthorization($0) }
                        // if there are other types of requests, do not block auth if passkey fails
                        .recoverWith { requestTypes.count != 1 ? Future(value: nil) : Future(error: $0) }
                }
            }
            .onSuccess { requests in
                let authController = ASAuthorizationController(authorizationRequests: requests.compactMap { $0 })
                authController.delegate = self
                authController.presentationContextProvider = self
                switch mode {
                case .Always:
                    // If credentials are available, presents a modal sign-in sheet.
                    // If there are no locally saved credentials, the system presents a QR code to allow signing in with a
                    // passkey from a nearby device.
                    authController.performRequests()
                case .IfImmediatelyAvailableCredentials:
                    // If credentials are available, presents a modal sign-in sheet.
                    // If there are no locally saved credentials, no UI appears and
                    // the system passes ASAuthorizationError.Code.canceled to call
                    // `AccountManager.authorizationController(controller:didCompleteWithError:)`.
                    if #available(iOS 16.0, *) { // no need to have a fallback in case iOS < 16, because .IfImmediatelyAvailableCredentials is already requiring iOS 16
                        authController.performRequests(options: .preferImmediatelyAvailableCredentials)
                    }
                }
                
                self.authController = authController
                self.isPerformingModalReqest = true
            }
            .onFailure { error in self.promise.failure(error) }
        
        return promise.future
    }
    
    @available(iOS 16.0, *)
    private func createCredentialAssertionRequest(_ assertionRequestOptions: AuthenticationOptions) -> Result<ASAuthorizationPlatformPublicKeyCredentialAssertionRequest, ReachFiveError> {
        guard let challenge = assertionRequestOptions.publicKey.challenge.decodeBase64Url() else {
            return .failure(.TechnicalError(reason: "unreadable challenge: \(assertionRequestOptions.publicKey.challenge)"))
        }
        
        //FIXME utiliser domain ou origin (sans le https) tel que passée en param ?
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: reachFiveApi.sdkConfig.domain)
        return .success(publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge))
    }
    
    private func adaptAuthz(_ nda: NonDiscoverableAuthorization) -> ModalAuthorization? {
        if #available(iOS 16.0, *), nda == .Passkey {
            return ModalAuthorization.Passkey
        }
        return nil
    }
}

extension CredentialManager: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        authenticationAnchor!
    }
}

extension CredentialManager: ASAuthorizationControllerDelegate {
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        defer {
            authController = nil
            isPerformingModalReqest = false
            signupOrAddPasskey = nil
            scope = nil
        }
        
        if let passwordCredential = authorization.credential as? ASPasswordCredential {
            // a password was selected to sign in
            let email: String?
            let phoneNumber: String?
            if passwordCredential.user.contains("@") {
                email = passwordCredential.user
                phoneNumber = nil
            } else {
                email = nil
                phoneNumber = passwordCredential.user
            }
            promise.completeWith(reachFiveApi.loginWithPassword(loginRequest: LoginRequest(
                email: email,
                phoneNumber: phoneNumber,
                customIdentifier: nil, // No custom identifier for login because no custom identifier can be used for signup
                password: passwordCredential.password,
                grantType: "password",
                clientId: reachFiveApi.sdkConfig.clientId,
                scope: scope ?? ""
            )))
        } else if #available(iOS 16.0, *), let credentialRegistration = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
            // A new passkey was registered
            guard let attestationObject = credentialRegistration.rawAttestationObject else {
                promise.tryFailure(.TechnicalError(reason: "no attestationObject"))
                registrationPromise.tryFailure(.TechnicalError(reason: "no attestationObject"))
                return
            }
            
            let clientDataJSON = credentialRegistration.rawClientDataJSON
            let r5AuthenticatorAttestationResponse = R5AuthenticatorAttestationResponse(attestationObject: attestationObject.toBase64Url(), clientDataJSON: clientDataJSON.toBase64Url())
            
            let id = credentialRegistration.credentialID.toBase64Url()
            let registrationPublicKeyCredential = RegistrationPublicKeyCredential(id: id, rawId: id, type: "public-key", response: r5AuthenticatorAttestationResponse)
            
            if let signupOrAddPasskey {
                switch signupOrAddPasskey {
                case .Signup(signupOptions: let signupOptions):
                    let webauthnSignupCredential = WebauthnSignupCredential(webauthnId: signupOptions.options.publicKey.user.id, publicKeyCredential: registrationPublicKeyCredential)
                    
                    promise.completeWith(reachFiveApi.signupWithWebAuthn(webauthnSignupCredential: webauthnSignupCredential))
                    return
                case .AddPasskey(authToken: let authToken):
                    registrationPromise.completeWith(reachFiveApi.registerWithWebAuthn(authToken: authToken, publicKeyCredential: registrationPublicKeyCredential))
                    return
                }
            }
            promise.tryFailure(.TechnicalError(reason: "no signupOptions"))
            registrationPromise.tryFailure(.TechnicalError(reason: "no token"))
        } else if #available(iOS 16.0, *), let credentialAssertion = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
            // A passkey was selected to sign in
            let signature = credentialAssertion.signature.toBase64Url()
            let clientDataJSON = credentialAssertion.rawClientDataJSON.toBase64Url()
            let userID = credentialAssertion.userID.toBase64Url()
            
            let id = credentialAssertion.credentialID.toBase64Url()
            let authenticatorData = credentialAssertion.rawAuthenticatorData.toBase64Url()
            let response = R5AuthenticatorAssertionResponse(authenticatorData: authenticatorData, clientDataJSON: clientDataJSON, signature: signature, userHandle: userID)
            promise.completeWith(reachFiveApi.authenticateWithWebAuthn(authenticationPublicKeyCredential: AuthenticationPublicKeyCredential(id: id, rawId: id, type: "public-key", response: response)))
        } else {
            promise.tryFailure(.TechnicalError(reason: "Received unknown authorization type."))
            registrationPromise.tryFailure(.TechnicalError(reason: "Received unknown authorization type."))
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        defer {
            authController = nil
            isPerformingModalReqest = false
            signupOrAddPasskey = nil
            scope = nil
        }
        
        guard let authorizationError = error as? ASAuthorizationError else {
            promise.tryFailure(.TechnicalError(reason: "Error: \(error.localizedDescription)"))
            registrationPromise.tryFailure(.TechnicalError(reason: "Error: \(error.localizedDescription)"))
            return
        }
        if authorizationError.code == .canceled {
            // Either the system doesn't find any credentials and the request ends silently, or the user cancels the request.
            // This is a good time to show a traditional login form, or ask the user to create an account.
            if isPerformingModalReqest {
                promise.tryFailure(.AuthCanceled)
                registrationPromise.tryFailure(.AuthCanceled)
            }
        } else {
            // Another ASAuthorization error.
            // Note: The userInfo dictionary contains useful information.
            let userInfo = (error as NSError).userInfo
            print("Error: \(userInfo)")
            promise.tryFailure(.TechnicalError(reason: "Error: \(userInfo)"))
            registrationPromise.tryFailure(.TechnicalError(reason: "Error: \(userInfo)"))
        }
    }
}
