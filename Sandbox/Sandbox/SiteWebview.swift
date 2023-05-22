import UIKit
import WebKit
import SafariServices
import IdentitySdkCore
import Alamofire

class SiteWebview: UIViewController {
    var webView: WKWebView!
    let myURL = URL(string: "https://integ-qa-fonctionnelle-pr3421.reach5.net/auth")!
    
    override func viewWillAppear(_ animated: Bool) {
        print("SiteWebview.viewWillAppear")
        super.viewWillAppear(animated)
        loadWk()
    }
    
    func loadWk() {
        // dd@dd.dd
        // azrAZR124&é'!
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            print("SiteWebview cookies.count \(cookies.count)")
            cookies.forEach {
                print($0.name + "\t\t" + $0.domain + "\t\t" + $0.value)
            }
        }
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: view.frame.width, height: view.frame.height))
        webView = WKWebView(frame: rect, configuration: webConfiguration)
        view = webView
        webView.load(URLRequest(url: myURL))
    }
    
}
