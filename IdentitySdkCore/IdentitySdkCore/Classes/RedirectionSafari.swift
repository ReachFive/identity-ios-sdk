import UIKit
import SafariServices
import BrightFutures

class RedirectionSafari: NSObject, SFSafariViewControllerDelegate
{
    var url: String
    private let notificationName = Notification.Name("AuthCallbackNotification")
    private var safariViewController: SFSafariViewController? = nil
    private var promise: Promise<String, ReachFiveError>?
    var name: String = "webview"
    
    public init(url: String) {
        self.url = url
    }
    
    public func login() -> Future<String, ReachFiveError> {
        self.promise?.tryFailure(.AuthCanceled)
        let promise = Promise<String, ReachFiveError>()
        self.promise = promise
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleLogin(_:)), name: self.notificationName, object: nil)
        self.safariViewController = SFSafariViewController.init(url: URL(string: url)!)
        self.safariViewController?.delegate = self
        UIApplication.shared.keyWindow?.rootViewController?.present(safariViewController!, animated: true)
        return promise.future
    }
    
    @objc func handleLogin(_ notification : Notification) {
        NotificationCenter.default.removeObserver(self, name: self.notificationName, object: nil)
        
        let url = notification.object as? URL
        if let query = url?.query {
            let params = QueryString.parseQueriesStrings(query: query)
            let code = params["code"]
            if code != nil {
                self.promise?.success(code!!)
            } else {
                self.promise?.failure(.TechnicalError(reason: "No authorization code"))
            }
        } else {
            self.promise?.failure(.TechnicalError(reason: "No authorization code"))
        }
        self.safariViewController?.dismiss(animated: true, completion: nil)
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        NotificationCenter.default.removeObserver(self, name: self.notificationName, object: nil)
        controller.dismiss(animated: true, completion: nil)
    }
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        if let sourceApplication = options[.sourceApplication] {
            if (String(describing: sourceApplication) == "com.apple.SafariViewService") {
                NotificationCenter.default.post(name: self.notificationName, object: url)
                return true
            }
        }
        
        return false
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return true
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
    }
    
    func logout() -> Future<(), ReachFiveError> {
        return Future.init(value: ())
    }
    
    func handleResult(result: Result<String, ReachFiveError>) -> String {
        var resultcode = String()
        switch result {
        case .success(let code):
            resultcode = code
        case .failure: break
        }
        return resultcode
    }
}
