import Foundation
import BrightFutures

public enum PasswordLessRequest {
    case Email(email: String, redirectUri: String?)
    case PhoneNumber(phoneNumber: String, redirectUri: String?)
}

public extension ReachFive {
    
    func addPasswordlessCallback(passwordlessCallback: @escaping PasswordlessCallback) {
        self.passwordlessCallback = passwordlessCallback
    }
    
    func startPasswordless(_ request: PasswordLessRequest) -> Future<(), ReachFiveError> {
        let pkce = Pkce.generate()
        storage.save(key: pkceKey, value: pkce)
        switch request {
        case let .Email(email, redirectUri):
            let startPasswordlessRequest = StartPasswordlessRequest(
                clientId: sdkConfig.clientId,
                email: email,
                authType: .MagicLink,
                redirectUri: redirectUri ?? sdkConfig.scheme,
                codeChallenge: pkce.codeChallenge,
                codeChallengeMethod: pkce.codeChallengeMethod
            )
            return reachFiveApi.startPasswordless(startPasswordlessRequest)
        case let .PhoneNumber(phoneNumber, redirectUri):
            let startPasswordlessRequest = StartPasswordlessRequest(
                clientId: sdkConfig.clientId,
                phoneNumber: phoneNumber,
                authType: .SMS,
                redirectUri: redirectUri ?? sdkConfig.scheme,
                codeChallenge: pkce.codeChallenge,
                codeChallengeMethod: pkce.codeChallengeMethod
            )
            return reachFiveApi.startPasswordless(startPasswordlessRequest)
        }
    }
    
    func verifyPasswordlessCode(verifyAuthCodeRequest: VerifyAuthCodeRequest) -> Future<AuthToken, ReachFiveError> {
        let pkce: Pkce? = storage.take(key: pkceKey)
        guard let pkce else {
            return Future(error: .TechnicalError(reason: "Pkce not found"))
        }
        return reachFiveApi
            .verifyAuthCode(verifyAuthCodeRequest: verifyAuthCodeRequest)
            .flatMap { _ in
                let verifyPasswordlessRequest = VerifyPasswordlessRequest(
                    email: verifyAuthCodeRequest.email,
                    phoneNumber: verifyAuthCodeRequest.phoneNumber,
                    verificationCode: verifyAuthCodeRequest.verificationCode,
                    state: "passwordless",
                    clientId: self.sdkConfig.clientId,
                    responseType: "code"
                )
                return self.reachFiveApi
                    .verifyPasswordless(verifyPasswordlessRequest: verifyPasswordlessRequest)
                    .flatMap { response in
                        let authCodeRequest = AuthCodeRequest(
                            clientId: self.sdkConfig.clientId,
                            code: response.code ?? "",
                            redirectUri: self.sdkConfig.scheme,
                            pkce: pkce
                        )
                        return self.reachFiveApi.authWithCode(authCodeRequest: authCodeRequest)
                            .flatMap({ AuthToken.fromOpenIdTokenResponseFuture($0) })
                    }
            }
    }
    
    internal func interceptPasswordless(_ url: URL) {
        let params = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems
        
        let pkce: Pkce? = storage.take(key: pkceKey)
        guard let pkce else {
            passwordlessCallback?(.failure(.TechnicalError(reason: "Pkce not found")))
            return
        }
        if let params, let code = params.first(where: { $0.name == "code" })?.value {
            let authCodeRequest = AuthCodeRequest(
                clientId: sdkConfig.clientId,
                code: code,
                redirectUri: sdkConfig.scheme,
                pkce: pkce
            )
            
            reachFiveApi.authWithCode(authCodeRequest: authCodeRequest)
                .flatMap({ AuthToken.fromOpenIdTokenResponseFuture($0) })
                .onComplete { result in
                    self.passwordlessCallback?(result)
                }
        }
    }
}
