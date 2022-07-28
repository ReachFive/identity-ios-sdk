import Foundation
import AuthenticationServices

public class WebviewLoginRequest {
    public let scope: [String]?
    public let presentationContextProvider: ASWebAuthenticationPresentationContextProviding

    public init(scope: [String]? = nil, presentationContextProvider: ASWebAuthenticationPresentationContextProviding) {
        self.scope = scope
        self.presentationContextProvider = presentationContextProvider
    }
}
