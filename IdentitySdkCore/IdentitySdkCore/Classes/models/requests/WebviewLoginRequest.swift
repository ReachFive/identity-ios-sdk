import Foundation
import AuthenticationServices

public class WebviewLoginRequest {
    public let state: String
    public let nonce: String
    public let scope: [String]?
    public let presentationContextProvider: ASWebAuthenticationPresentationContextProviding

    public init(state: String, nonce: String, scope: [String]?, presentationContextProvider: ASWebAuthenticationPresentationContextProviding) {
        self.state = state
        self.nonce = nonce
        self.scope = scope
        self.presentationContextProvider = presentationContextProvider
    }
}
