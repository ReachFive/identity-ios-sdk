import Foundation
import PromiseKit
import WebAuthnKit
import BrightFutures

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

public enum FormError : Error {
    case missing(String)
    case empty(String)
}

class ReachFiveFidoClient: NSObject
{
    var webAuthnClient: WebAuthnClient!
    var userConsentUI: UserConsentUI!
    let viewController: UIViewController
    let origin: String
    
    public  init(viewController: UIViewController, origin: String) {
        self.viewController = viewController
        self.origin = origin
    }
    
    func setupWebAuthnClient() {
        WAKLogger.available = true
        
        self.userConsentUI = UserConsentUI(viewController: self.viewController)
        self.userConsentUI.config.showRPInformation = false
        self.userConsentUI.config.fieldTextLightColor = UIColor.black
        let authenticator = InternalAuthenticator(ui: self.userConsentUI)
        self.webAuthnClient = WebAuthnClient(
            origin:        self.origin,
            authenticator: authenticator
        )
    }
    func startRegistration(registrationOption: RegistrationOptions) -> Future<WebauthnSignupCredential, Error> {
        
        var challenge = registrationOption.options.publicKey.challenge
        let userId = registrationOption.options.publicKey.user.id
        let userName = registrationOption.options.publicKey.user.name
        let displayName = registrationOption.options.publicKey.user.displayName
        let rpId = registrationOption.options.publicKey.rp.id
        
        let requireResidentKey = true
        var options = PublicKeyCredentialCreationOptions()
        challenge = base64urlToHexString(base64url: challenge)
        
        options.challenge = Bytes.fromHex(challenge)
        options.user.id = Bytes.fromString(userId)
        options.user.name = userName
        options.user.displayName = displayName
        options.rp.id = rpId
        options.rp.name = rpId
        
        options.attestation = .direct
        options.addPubKeyCredParam(alg: .es256)
        options.authenticatorSelection = AuthenticatorSelectionCriteria(
            requireResidentKey: requireResidentKey,
            userVerification: UserVerificationRequirement.required
        )
        
        let thePromise = BrightFutures.Promise<WebauthnSignupCredential, Error>()
        firstly {
            self.webAuthnClient.create(options)
        }.done { credential in
            
            let rawId = credential.rawId.toHexString()
            let credId = credential.id
            let credType = credential.type.rawValue
            let clientDataJSON = self.encodeClientDataJsonToBase64(clientDataJson: credential.response.clientDataJSON)
            let attestationObject = Base64.encodeBase64URL(credential.response.attestationObject)
            
            let r5AuthenticatorAttestationResponse = R5AuthenticatorAttestationResponse(attestationObject: attestationObject,clientDataJSON: clientDataJSON)
            
            let registrationPublicKeyCredential = RegistrationPublicKeyCredential(id: credId,rawId: rawId,type: credType,response: r5AuthenticatorAttestationResponse)
            
            let webauthnSignupCredential = WebauthnSignupCredential (webauthnId: userId,publicKeyCredential: registrationPublicKeyCredential)
            let result: Swift.Result<WebauthnSignupCredential, Error> = Swift.Result.success(webauthnSignupCredential)
            thePromise.complete(result)
            
        }.catch { error in
            thePromise.failure(error)
        }
        
        return thePromise.future
    }
    
    func base64urlToHexString(base64url: String) -> String {
        var hexString = base64url
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if hexString.count % 4 != 0 {
            hexString.append(String(repeating: "=", count: 4 - hexString.count % 4))
        }
        if let data = Data(base64Encoded: hexString) {
            hexString = data.hexEncodedString()
        }
        return hexString
    }
    
    func encodeClientDataJsonToBase64(clientDataJson: String) -> String {
        
        let utf8str = clientDataJson.data(using: .utf8)
        var encodeClientDataJSON = ""
        if let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
            encodeClientDataJSON = base64Encoded
        }
        return encodeClientDataJSON
    }
    
    func startAuthentication(authenticationOptions: AuthenticationOptions) -> Future<AuthenticationPublicKeyCredential, Error> {
        var challenge = authenticationOptions.publicKey.challenge
        let rpId = authenticationOptions.publicKey.rpId
        
        // Decode challenge from Base64Url to HexString
        challenge = base64urlToHexString(base64url: challenge)
        // prepare PublicKeyCredentialRequestOptions
        var options = PublicKeyCredentialRequestOptions()
        options.challenge = Bytes.fromHex(challenge)
        options.rpId = rpId
        options.userVerification = UserVerificationRequirement.required
        
        for allowCredentials in authenticationOptions.publicKey.allowCredentials! {
            // Decode credentialId from Base64Url to HexString
            allowCredentials.id = base64urlToHexString(base64url: allowCredentials.id)
            if !allowCredentials.id.isEmpty {
                options.addAllowCredential(
                    credentialId: Bytes.fromHex(allowCredentials.id),
                    transports:   [.internal_]
                )
            }
        }
        let thePromise = BrightFutures.Promise<AuthenticationPublicKeyCredential, Error>()
        firstly {
            self.webAuthnClient.get(options)
        }.done { assertion in
            
            let user: [UInt8] = assertion.response.userHandle ?? []
            let userName = String(data: Data(_: user), encoding: .utf8) ?? ""
            let rawId = assertion.rawId.toHexString()
            let credId = assertion.id
            let credType = assertion.type.rawValue
            let clientDataJSON = self.encodeClientDataJsonToBase64(clientDataJson: assertion.response.clientDataJSON)
            let authenticatorData = Base64.encodeBase64URL(assertion.response.authenticatorData)
            let signature = Base64.encodeBase64URL(assertion.response.signature)
            let userHandle = userName
            
            let r5AuthenticatorAssertionResponse = R5AuthenticatorAssertionResponse (authenticatorData: authenticatorData, clientDataJSON: clientDataJSON, signature: signature, userHandle: userHandle)
            
            let authenticationPublicKeyCredential = AuthenticationPublicKeyCredential (id: credId, rawId: rawId, type: credType, response: r5AuthenticatorAssertionResponse)
            
            let result: Swift.Result<AuthenticationPublicKeyCredential, Error> = Swift.Result.success(authenticationPublicKeyCredential)
            thePromise.complete(result)
            
        }.catch { error in
            thePromise.failure(error)
        }
        
        return thePromise.future
    }
}

