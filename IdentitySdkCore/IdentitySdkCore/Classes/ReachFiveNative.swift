import Foundation
import AuthenticationServices
import BrightFutures


public extension ReachFive {
// On naming and signature for methods:
// first argument indicates modality to distinguish the two primary way UI is shown to user: Modal and AutoFill
// first argument label contains "with" instead of the method name in conformance to https://www.swift.org/documentation/api-design-guidelines/#give-prepositional-phrase-argument-label
// autoFill and non-discoverable methods also take a requestType parameter even though there is only one such type:
//      1. to make it very clear that we are using passkeys
//      2. to be future proof. For non-discoverable, there is already Security Keys that exist and that we could support.
// AutoFill is @available(iOS 16.0, *) because ASAuthorizationController.performAutoFillAssistedRequests() itself is
// the other methods control version availability with their respective Authorization enum to increase flexibility
// For example the non-discoverable cannot be declared @available(iOS 16.0, *)
// because in the future we could support Security Keys, which are available since iOS 15
    
    @available(iOS 16.0, *)
    func signup(withRequest request: PasskeySignupRequest) -> Future<AuthToken, ReachFiveError> {
        let domain = sdkConfig.domain
        let signupOptions = SignupOptions(
            origin: request.origin ?? "https://\(domain)",
            friendlyName: request.friendlyName,
            profile: request.passkeyPofile,
            clientId: sdkConfig.clientId,
            scope: request.scopes ?? scope
        )
        
        return credentialManager.signUp(withRequest: signupOptions, anchor: request.anchor)
            .flatMap({ self.loginCallback(tkn: $0.tkn, scopes: request.scopes) })
    }
    
    // https://developer.apple.com/forums/thread/714608
    // il y a un bug quand on touche la clé pour afficher les diverses clés d'identification présentes
    @available(iOS 16.0, *)
    func login(withRequest request: NativeLoginRequest, usingAutoFillAuthorizationFor requestType: AutoFillAuthorization) -> Future<AuthToken, ReachFiveError> {
        credentialManager.beginAutoFillAssistedPasskeySignIn(request: adapt(request))
            .flatMap({ self.loginCallback(tkn: $0.tkn, scopes: request.scopes) })
    }
    
    /// Signs in the user using credentials stored in the keychain, letting the system display all credentials available to choose from.
    func login(withRequest request: NativeLoginRequest, usingModalAuthorizationFor requestTypes: [ModalAuthorization], display mode: Mode) -> Future<AuthToken, ReachFiveError> {
        credentialManager.login(withRequest: adapt(request), usingModalAuthorizationFor: requestTypes, display: mode)
            .flatMap({ self.loginCallback(tkn: $0.tkn, scopes: request.scopes) })
    }
    
    func login(withNonDiscoverableUsername username: Username, forRequest request: NativeLoginRequest, usingModalAuthorizationFor requestTypes: [NonDiscoverableAuthorization], display mode: Mode) -> Future<AuthToken, ReachFiveError> {
        credentialManager.login(withNonDiscoverableUsername: username, forRequest: adapt(request), usingModalAuthorizationFor: requestTypes, display: mode)
            .flatMap({ self.loginCallback(tkn: $0.tkn, scopes: request.scopes) })
    }
    //TODO doc
    @available(iOS 16.0, *)
    func registerNewPasskey(withRequest request: NewPasskeyRequest, authToken: AuthToken) -> Future<(), ReachFiveError> {
        let domain = reachFiveApi.sdkConfig.domain
        let origin = request.origin ?? "https://\(domain)"
        //TODO supprimer l'ancienne passkey du server
        return credentialManager.registerNewPasskey(withRequest: NewPasskeyRequest(anchor: request.anchor, friendlyName: request.friendlyName, origin: origin), authToken: authToken)
    }
    
    private func adapt(_ request: NativeLoginRequest) -> NativeLoginRequest {
        let domain = reachFiveApi.sdkConfig.domain
        let origin = request.origin ?? "https://\(domain)"
        let scopes = request.scopes ?? scope
        
        return NativeLoginRequest(anchor: request.anchor, origin: origin, scopes: scopes)
    }
}

public enum Username {
    case Unspecified(_ username: String)
    case Email(_ email: String)
    case PhoneNumber(_ phoneNumber: String)
}

public enum ModalAuthorization: Equatable {
    case Password
    @available(iOS 16.0, *)
    case Passkey
}

public enum NonDiscoverableAuthorization: Equatable {
    @available(iOS 16.0, *)
    case Passkey
}

public enum AutoFillAuthorization: Equatable {
    case Passkey
}

public enum Mode: Equatable {
    /// If credentials are available, presents a modal sign-in sheet.
    /// If there are no locally saved credentials, the system presents a QR code to allow signing in with a passkey from a nearby device.
    /// Corresponds to `AuthController.performRequests()`
    case Always
    /// If credentials are available, presents a modal sign-in sheet.
    /// If there are no locally saved credentials, no UI appears and
    /// the call ends in ReachFiveError.AuthCanceled
    /// Corresponds to `AuthController.performRequests(options: .preferImmediatelyAvailableCredentials)`
    @available(iOS 16.0, *)
    case IfImmediatelyAvailableCredentials
}
