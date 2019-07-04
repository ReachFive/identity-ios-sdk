import Foundation
import Alamofire
import AlamofireObjectMapper

typealias ResponseHandler<T> = (_ response: DataResponse<T>) -> Void

public class ReachFiveApi {
    let sdkConfig: SdkConfig
    
    public init(sdkConfig: SdkConfig) {
        self.sdkConfig = sdkConfig
    }
    
    public func providersConfigs(callback: @escaping Callback<ProvidersConfigsResult, ReachFiveError>) {
        Alamofire
            .request(createUrl(path: "/api/v1/providers?platform=ios"))
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseObject(completionHandler: handleResponse(callback: callback))
    }
    
    public func loginWithProvider(loginProviderRequest: LoginProviderRequest, callback: @escaping Callback<AccessTokenResponse, ReachFiveError>) {
        Alamofire
            .request(createUrl(path: "/identity/v1/oauth/provider/token"), method: .post, parameters: loginProviderRequest.toJSON(), encoding: JSONEncoding.default)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseObject(completionHandler: handleResponse(callback: callback))
    }
    
    public func signupWithPassword(signupRequest: SignupRequest, callback: @escaping Callback<AccessTokenResponse, ReachFiveError>) {
        Alamofire
            .request(createUrl(path: "/identity/v1/signup-token"), method: .post, parameters: signupRequest.toJSON(), encoding: JSONEncoding.default)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseObject(completionHandler: handleResponse(callback: callback))
    }
    
    public func loginWithPassword(loginRequest: LoginRequest, callback: @escaping Callback<AccessTokenResponse, ReachFiveError>) {
        Alamofire
            .request(createUrl(path: "/oauth/token"), method: .post, parameters: loginRequest.toJSON(), encoding: JSONEncoding.default)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseObject(completionHandler: handleResponse(callback: callback))
    }
    
    public func authWithCode(authCodeRequest: AuthCodeRequest, callback: @escaping Callback<AccessTokenResponse, ReachFiveError>) {
        Alamofire
            .request(createUrl(path: "/oauth/token"), method: .post, parameters: authCodeRequest.toJSON(), encoding: JSONEncoding.default)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseObject(completionHandler: handleResponse(callback: callback))
    }
    
    func handleResponse<T>(callback: @escaping Callback<T, ReachFiveError>) -> ResponseHandler<T> {
        return {(response: DataResponse<T>) -> Void in
            switch response.result {
            case let .failure(error): callback(.failure(.TechnicalError(reason: error.localizedDescription)))
            case let .success(value): callback(.success(value))
            }
        }
    }
    
    func createUrl(path: String) -> String {
        return "https://\(sdkConfig.domain)\(path)"
    }
}
