import UIKit
import WebKit
import Alamofire
import BrightFutures

public class LoginWKWebview: UIView {
    var webView: WKWebView!
    var reachfive: ReachFive?
    var promise: Promise<AuthToken, ReachFiveError>?
    var pkce: Pkce?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public func loadLoginWebview(reachfive: ReachFive, promise: Promise<AuthToken, ReachFiveError>, state: String? = nil, nonce: String? = nil, scope: [String]? = nil) {
        let pkce = Pkce.generate()
        
        self.reachfive = reachfive
        self.promise = promise
        self.pkce = pkce
        
        let scope = (scope ?? reachfive.scope).joined(separator: " ")
        var options = [
            "client_id": reachfive.sdkConfig.clientId,
            "redirect_uri": reachfive.sdkConfig.scheme,
            "response_type": "code",
            "scope": scope,
            "code_challenge": pkce.codeChallenge,
            "code_challenge_method": pkce.codeChallengeMethod
        ]
        if let state {
            options["state"] = state
        }
        if let nonce {
            options["nonce"] = nonce
        }
        
        let authURL = reachfive.reachFiveApi.buildAuthorizeURL(queryParams: options)
        webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.navigationDelegate = self
        addSubview(webView)
        
        webView.load(URLRequest(url: authURL))
    }
}

extension LoginWKWebview: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> ()) {
        guard let reachfive, let promise, let pkce else {
            decisionHandler(.allow)
            print("no reachfive, promise, pkce")
            return
        }
        if let url = navigationAction.request.url, url.scheme == reachfive.sdkConfig.baseScheme {
            decisionHandler(.cancel)
            let params = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems
            guard let params, let code = params.first(where: { $0.name == "code" })?.value else {
                promise.failure(.TechnicalError(reason: "No authorization code"))
                return
            }
            
            promise.completeWith(reachfive.authWithCode(code: code, pkce: pkce))
        }
        decisionHandler(.allow)
    }
}
