import Alamofire
import BrightFutures

public class ReachFiveApi {
    let decoder = JSONDecoder()
    let sdkConfig: SdkConfig
    
    private let profile_fields = [
        "birthdate",
        "bio",
        "middle_name",
        "addresses",
        "auth_types",
        "consents",
        "created_at",
        "custom_fields",
        "devices",
        "company",
        "email",
        "emails",
        "email_verified",
        "external_id",
        "family_name",
        "first_login",
        "first_name",
        "full_name",
        "gender",
        "given_name",
        "has_managed_profile",
        "has_password",
        "id",
        "identities",
        "last_login",
        "last_login_provider",
        "last_login_type",
        "last_name",
        "likes_friends_ratio",
        "lite_only",
        "locale",
        "local_friends_count",
        "login_summary",
        "logins_count",
        "name",
        "nickname",
        "origins",
        "picture",
        "phone_number",
        "phone_number_verified",
        "provider_details",
        "providers",
        "social_identities",
        "sub",
        "uid",
        "updated_at"
    ]
    
    let deviceInfo: String = "\(UIDevice.current.modelName) \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    
    public init(sdkConfig: SdkConfig) {
        self.sdkConfig = sdkConfig
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    public func clientConfig() -> Future<ClientConfigResponse, ReachFiveError> {
        return AF
            .request(createUrl(path: "/identity/v1/config?client_id=\(sdkConfig.clientId)"))
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJson(type: ClientConfigResponse.self, decoder: self.decoder)
    }
    
    public func providersConfigs() -> Future<ProvidersConfigsResult, ReachFiveError> {
        return AF
            .request(createUrl(path: "/api/v1/providers?platform=ios&device=\(deviceInfo)"))
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJson(type: ProvidersConfigsResult.self, decoder: self.decoder)
    }
    
    public func loginWithProvider(
        loginProviderRequest: LoginProviderRequest
    ) -> Future<AccessTokenResponse, ReachFiveError> {
        return AF
            .request(createUrl(path: "/identity/v1/oauth/provider/token?device=\(deviceInfo)"), method: .post, parameters: loginProviderRequest.dictionary(), encoding: JSONEncoding.default)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJson(type: AccessTokenResponse.self, decoder: self.decoder)
    }
    
    public func signupWithPassword(signupRequest: SignupRequest) -> Future<AccessTokenResponse, ReachFiveError> {
        return AF
            .request(
                createUrl(path: "/identity/v1/signup-token?device=\(deviceInfo)"),
                method: .post,
                parameters: signupRequest.dictionary(),
                encoding: JSONEncoding.default
        )
            .validate(contentType: ["application/json"])
            .responseJson(type: AccessTokenResponse.self, decoder: self.decoder)
    }
    
    public func loginWithPassword(loginRequest: LoginRequest) -> Future<AccessTokenResponse, ReachFiveError> {
        return AF
            .request(
                createUrl(path: "/oauth/token?device=\(deviceInfo)"),
                method: .post,
                parameters: loginRequest.dictionary(),
                encoding: JSONEncoding.default
        )
            .validate(contentType: ["application/json"])
            .responseJson(type: AccessTokenResponse.self, decoder: self.decoder)
    }
    
    public func authWithCode(authCodeRequest: AuthCodeRequest) -> Future<AccessTokenResponse, ReachFiveError> {
        return AF
            .request(
                createUrl(path: "/oauth/token?device=\(deviceInfo)"),
                method: .post,
                parameters: authCodeRequest.dictionary(),
                encoding: JSONEncoding.default
        )
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJson(type: AccessTokenResponse.self, decoder: self.decoder)
    }
    
    public func refreshAccessToken(_ refreshRequest: RefreshRequest) -> Future<AccessTokenResponse, ReachFiveError> {
        return AF
            .request(
                createUrl(path: "/oauth/token?device=\(deviceInfo)"),
                method: .post,
                parameters: refreshRequest.dictionary(),
                encoding: JSONEncoding.default
        )
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJson(type: AccessTokenResponse.self, decoder: self.decoder)
    }
    
    public func getProfile(authToken: AuthToken) -> Future<Profile, ReachFiveError> {
        return AF
            .request(
                createUrl(
                    path: "/identity/v1/me?device=\(deviceInfo)&fields=\(profile_fields.joined(separator: ","))"
                ),
                method: .get,
                headers: tokenHeader(authToken)
        )
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJson(type: Profile.self, decoder: self.decoder)
    }
    
    public func verifyPhoneNumber(
        authToken: AuthToken,
        verifyPhoneNumberRequest: VerifyPhoneNumberRequest
    ) -> Future<(), ReachFiveError> {
        return AF
            .request(
                createUrl(path: "/identity/v1/verify-phone-number?device=\(deviceInfo)"),
                method: .post,
                parameters: verifyPhoneNumberRequest.dictionary(),
                encoding: JSONEncoding.default,
                headers: tokenHeader(authToken)
        )
            .validate(contentType: ["application/json"])
            .responseJson(decoder: self.decoder)
    }
    
    public func updateEmail(
        authToken: AuthToken,
        updateEmailRequest: UpdateEmailRequest
    ) -> Future<Profile, ReachFiveError> {
        return AF
            .request(
                createUrl(path: "/identity/v1/update-email?device=\(deviceInfo)"),
                method: .post,
                parameters: updateEmailRequest.dictionary(),
                encoding: JSONEncoding.default,
                headers: tokenHeader(authToken)
        )
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJson(type: Profile.self, decoder: self.decoder)
    }
    
    public func updateProfile(
        authToken: AuthToken,
        profile: Profile
    ) -> Future<Profile, ReachFiveError> {
        return AF
            .request(
                createUrl(path: "/identity/v1/update-profile?device=\(deviceInfo)"),
                method: .post,
                parameters: profile.dictionary(),
                encoding: JSONEncoding.default,
                headers: tokenHeader(authToken)
        )
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJson(type: Profile.self, decoder: self.decoder)
    }
    
    public func updatePassword(
        authToken: AuthToken?,
        updatePasswordRequest: UpdatePasswordRequest
    ) -> Future<(), ReachFiveError> {
        let headers: HTTPHeaders = authToken != nil ? tokenHeader(authToken!) : [:]
        return AF
            .request(
                createUrl(path: "/identity/v1/update-password?device=\(deviceInfo)"),
                method: .post,
                parameters: updatePasswordRequest.dictionary(),
                encoding: JSONEncoding.default,
                headers: headers
        )
            .validate(contentType: ["application/json"])
            .responseJson(decoder: self.decoder)
    }
    
    public func updatePhoneNumber(
        authToken: AuthToken,
        updatePhoneNumberRequest: UpdatePhoneNumberRequest
    ) -> Future<Profile, ReachFiveError> {
        return AF
            .request(
                createUrl(path: "/identity/v1/update-phone-number?device=\(deviceInfo)"),
                method: .post,
                parameters: updatePhoneNumberRequest.dictionary(),
                encoding: JSONEncoding.default,
                headers: tokenHeader(authToken)
        )
            .validate(contentType: ["application/json"])
            .responseJson(type: Profile.self, decoder: self.decoder)
    }
    
    public func requestPasswordReset(
        requestPasswordResetRequest: RequestPasswordResetRequest
    ) -> Future<(), ReachFiveError> {
        return AF
            .request(createUrl(
                path: "/identity/v1/forgot-password?device=\(deviceInfo)"),
                     method: .post,
                     parameters: requestPasswordResetRequest.dictionary(),
                     encoding: JSONEncoding.default
        )
            .validate(contentType: ["application/json"])
            .responseJson(decoder: self.decoder)
    }
    
    public func startPasswordless(_ startPasswordlessRequest: StartPasswordlessRequest) -> Future<(), ReachFiveError> {
        return AF
            .request(
                createUrl(path: "/identity/v1/passwordless/start?device=\(deviceInfo)"),
                method: .post,
                parameters: startPasswordlessRequest.dictionary(),
                encoding: JSONEncoding.default
        )
            .validate(statusCode: 200..<300)
            .responseJson(decoder: self.decoder)
    }
    
    public func verifyPasswordless(verifyPasswordlessRequest: VerifyPasswordlessRequest) -> Future<PasswordlessVerifyResponse, ReachFiveError> {
        return AF
            .request(
                createUrl(path: "/identity/v1/passwordless/verify?device=\(deviceInfo)"),
                method: .post,
                parameters: verifyPasswordlessRequest.dictionary()
        )
            .validate(statusCode: 200..<300)
            .responseJson(type: PasswordlessVerifyResponse.self, decoder: self.decoder)
    }
    
    public func verifyAuthCode(verifyAuthCodeRequest: VerifyAuthCodeRequest) -> Future<(), ReachFiveError> {
        return AF
            .request(
                createUrl(path: "/identity/v1/verify-auth-code?device=\(deviceInfo)"),
                method: .post,
                parameters: verifyAuthCodeRequest.dictionary(),
                encoding: JSONEncoding.default
        )
            .validate(statusCode: 200..<300)
            .responseJson(decoder: self.decoder)
    }
    
    public func logout() -> Future<(), ReachFiveError> {
        return AF
            .request(
                createUrl(path: "/identity/v1/logout?device=\(deviceInfo)"),
                method: .get
        )
            .validate(statusCode: 200..<300)
            .responseJson(decoder: self.decoder)
    }
    
    func tokenHeader(_ authToken: AuthToken) -> HTTPHeaders {
        return ["Authorization": "\(authToken.tokenType ?? "Bearer") \(authToken.accessToken)"]
    }
    
    func createUrl(path: String) -> String {
        return "https://\(sdkConfig.domain)\(path)"
    }
    
    public func authorize(options: [String:String]) -> String {
        
        let request: URLRequest?
        var redirectUri = String()
        do {
            request = try URLRequest(url: createUrl(path: "/oauth/authorize?"), method: .get, headers: nil)
            let encodedURLRequest = try URLEncoding.queryString.encode(request!, with: options )
            redirectUri = "\(encodedURLRequest)"
            
        } catch {
            return "failed to build url"
        }
        return redirectUri
    }
    
    public func createWebAuthnSignupOptions(webAuthnRegistrationRequest: WebAuthnRegistrationRequest) -> Future<RegistrationOptions, ReachFiveError> {
        return AF
            .request(
                createUrl(path: "/identity/v1/webauthn/signup-options?device=\(deviceInfo)"),
                method: .post,
                parameters: webAuthnRegistrationRequest.dictionary(),
                encoding: JSONEncoding.default
        )
            .validate(contentType: ["application/json"])
            .responseJson(type: RegistrationOptions.self, decoder: self.decoder)
    }
    public func signupWithWebAuthn(webauthnSignupCredential: WebauthnSignupCredential) -> Future<AuthenticationToken, ReachFiveError> {
        return AF
            .request(
                createUrl(path: "/identity/v1/webauthn/signup?device=\(deviceInfo)"),
                method: .post,
                parameters: webauthnSignupCredential.dictionary(),
                encoding: JSONEncoding.default
        )
            .validate(contentType: ["application/json"])
            .responseJson(type: AuthenticationToken.self, decoder: self.decoder)
    }
    
    public func createWebAuthnAuthenticationOptions(webAuthnLoginRequest: WebAuthnLoginRequest) -> Future<AuthenticationOptions, ReachFiveError> {
        return AF
            .request(
                createUrl(path: "/identity/v1/webauthn/authentication-options?device=\(deviceInfo)"),
                method: .post,
                parameters: webAuthnLoginRequest.dictionary(),
                encoding: JSONEncoding.default
        )
            .validate(contentType: ["application/json"])
            .responseJson(type: AuthenticationOptions.self, decoder: self.decoder)
    }
    
    public func authenticateWithWebAuthn(authenticationPublicKeyCredential: AuthenticationPublicKeyCredential) -> Future<AuthenticationToken, ReachFiveError> {
        return AF
            .request(
                createUrl(path: "/identity/v1/webauthn/authentication?device=\(deviceInfo)"),
                method: .post,
                parameters: authenticationPublicKeyCredential.dictionary(),
                encoding: JSONEncoding.default
        )
            .validate(contentType: ["application/json"])
            .responseJson(type: AuthenticationToken.self, decoder: self.decoder)
    }
    
    public func getWebAuthnRegistrations(authorization: String) -> Future<[DeviceCredential], ReachFiveError> {
        
        let headers : HTTPHeaders = [ "Authorization" : authorization ]
        return AF
            .request(
                createUrl(path: "/identity/v1/webauthn/registration?device=\(deviceInfo)"),
                method: .get,
                encoding: JSONEncoding.default,
                headers: headers
        )
            .validate(contentType: ["application/json"])
            .responseJson(type: [DeviceCredential].self, decoder: self.decoder)
    }
}
