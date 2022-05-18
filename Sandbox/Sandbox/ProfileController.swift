import UIKit
import IdentitySdkCore

class ProfileController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var authToken: AuthToken? = AppDelegate.storage.get(key: AppDelegate.authKey)
    var devices : [DeviceCredential] = []
    
    @IBOutlet weak var familyNameLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var deviceFidoTableview: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        deviceFidoTableview.delegate = self
        deviceFidoTableview.dataSource = self
        
        AppDelegate.reachfive()
            .getProfile(authToken: self.authToken!)
            .onSuccess { profile in print("Profile = \(profile)")
                if profile.givenName != nil {
                    self.nameLabel?.text = "Given name: " + profile.givenName!
                }
                if profile.familyName != nil {
                    self.familyNameLabel?.text = "Family name: " + profile.familyName!
                }
                if profile.email != nil {
                    self.emailLabel?.text = "Email: " + profile.email!
                }
        }
        .onFailure { error in print("getProfile error = \(error)") }
        
        
        AppDelegate.reachfive().listWebAuthnDevices(authToken: self.authToken!).onSuccess { listDevice in
            self.devices.append(contentsOf: listDevice)
            
            DispatchQueue.main.async{
                self.deviceFidoTableview.reloadData()
            }
            
        }
        .onFailure { error in
            print("getDevices error = \(error)") }
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:DevicesFidoCell = self.deviceFidoTableview.dequeueReusableCell(withIdentifier: "deviceFidoCell") as! DevicesFidoCell
        cell.friendlyNameText.text = self.devices[indexPath.row].friendlyName
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    @IBAction func logoutAction(_ sender: Any) {
        AppDelegate.reachfive().logout()
            .onComplete { result in
                AppDelegate.storage.clear(key: AppDelegate.authKey)
                self.authToken = nil
                self.navigationController?.popViewController(animated: true)
        }
    }
}
