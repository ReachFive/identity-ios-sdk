import Foundation
import BrightFutures
import AuthenticationServices

public extension ReachFive {
    
    func webviewLogin(_ request: WebviewLoginRequest) -> Future<AuthToken, ReachFiveError> {
        
        let promise = Promise<AuthToken, ReachFiveError>()
        
        let pkce = Pkce.generate()
        let authURL = buildAuthorizeURL(pkce: pkce, state: request.state, nonce: request.nonce, scope: scope)
        
        // Initialize the session.
        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: reachFiveApi.sdkConfig.baseScheme) { callbackURL, error in
            guard error == nil else {
                let r5Error: ReachFiveError
                switch error!._code {
                case 1: r5Error = .AuthCanceled
                case 2: r5Error = .TechnicalError(reason: "Presentation Context Not Provided")
                case 3: r5Error = .TechnicalError(reason: "Presentation Context Invalid")
                default:
                    r5Error = .TechnicalError(reason: "Unknown Error")
                }
                promise.failure(r5Error)
                return
            }
            
            guard let callbackURL = callbackURL else {
                promise.failure(.TechnicalError(reason: "No callback URL"))
                return
            }
            
            let queryItems = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true)?.queryItems
            let code = queryItems?.first(where: { $0.name == "code" })?.value
            guard let code = code else {
                promise.failure(.TechnicalError(reason: "No authorization code"))
                return
            }
            
            promise.completeWith(self.authWithCode(code: code, pkce: pkce))
        }
        
        // Set an appropriate context provider instance that determines the window that acts as a presentation anchor for the session
        session.presentationContextProvider = request.presentationContextProvider
        
        // Start the Authentication Flow
        session.start()
        return promise.future
    }
}