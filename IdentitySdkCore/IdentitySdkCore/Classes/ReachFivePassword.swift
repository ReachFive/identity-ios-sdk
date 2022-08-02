import Foundation
import BrightFutures

public extension ReachFive {
    func signup(profile: ProfileSignupRequest, redirectUrl: String? = nil, scope: [String]? = nil) -> Future<AuthToken, ReachFiveError> {
        let signupRequest = SignupRequest(
            clientId: sdkConfig.clientId,
            data: profile,
            scope: (scope ?? self.scope).joined(separator: " "),
            redirectUrl: redirectUrl
        )
        return reachFiveApi
            .signupWithPassword(signupRequest: signupRequest)
            .flatMap({ AuthToken.fromOpenIdTokenResponseFuture($0) })
    }
    
    func loginWithPassword(
        username: String,
        password: String,
        scope: [String]? = nil
    ) -> Future<AuthToken, ReachFiveError> {
        let loginRequest = LoginRequest(
            username: username,
            password: password,
            grantType: "password",
            clientId: sdkConfig.clientId,
            scope: (scope ?? self.scope).joined(separator: " ")
        )
        return reachFiveApi
            .loginWithPassword(loginRequest: loginRequest)
            .flatMap({ AuthToken.fromOpenIdTokenResponseFuture($0) })
    }
}
