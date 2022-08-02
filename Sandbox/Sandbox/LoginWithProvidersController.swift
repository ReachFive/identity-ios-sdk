import UIKit
import IdentitySdkCore
import GoogleSignIn

class LoginWithProvidersController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var providers: [Provider] = []
    
    @IBOutlet weak var providersTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        providersTableView.dataSource = self
        providersTableView.delegate = self
        
        AppDelegate.reachfive()
            .initialize()
            .onSuccess { providers in
                self.providers.append(contentsOf: providers)
                self.providersTableView.reloadData()
            }
            .onFailure { print("initialize error \($0)") }
    }
    
    public func reloadProvidersData(providers: [Provider]) {
        self.providers = providers
        providersTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        providers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "providerCell")
        
        let provider = providers[indexPath.row]
        
        cell?.textLabel?.text = provider.name
        
        return cell!
    }
    
    func handleResult(result: Result<AuthToken, ReachFiveError>) {
        switch result {
        case .success(let authToken):
            AppDelegate.storage.save(key: AppDelegate.authKey, value: authToken)
            goToProfile(authToken)
        case .failure(let error):
            print(error)
        }
    }
    
    func goToProfile(_ authToken: AuthToken) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let profileController = storyBoard.instantiateViewController(
            withIdentifier: "ProfileScene"
        ) as! ProfileController
        navigationController?.pushViewController(profileController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedProvider = providers[indexPath.row]
        
        let scope = ["openid", "email", "profile", "phone", "full_write", "offline_access"]
        
        AppDelegate.reachfive()
            .getProvider(name: selectedProvider.name)?
            .login(
                scope: scope,
                origin: "home",
                viewController: self
            )
            .onComplete { result in
                self.handleResult(result: result)
            }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
}
