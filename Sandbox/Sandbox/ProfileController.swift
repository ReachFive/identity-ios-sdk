import UIKit
import IdentitySdkCore

class ProfileController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var authToken: AuthToken? = AppDelegate.storage.get(key: AppDelegate.authKey)
    var devices : [DeviceCredential] = []
    
    @IBOutlet weak var familyNameLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var deviceFidoTableview: UITableView!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var deviceNameText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        deviceNameText.text = UIDevice.current.name
        deviceFidoTableview.delegate = self
        deviceFidoTableview.dataSource = self
        
        AppDelegate.reachfive()
            .getProfile(authToken: self.authToken!)
            .onSuccess { profile in
                if profile.givenName != nil {
                    self.nameLabel?.text = "Given name: " + profile.givenName!
                }
                if profile.familyName != nil {
                    self.familyNameLabel?.text = "Family name: " + profile.familyName!
                }
                if profile.email != nil {
                    self.emailLabel?.text = "Email: " + profile.email!
                }
                if profile.phoneNumber != nil {
                    self.phoneLabel?.text = "Phone: " + profile.phoneNumber!
                }
            }
            .onFailure { error in
                self.alertError(error: error)
            }
        
        self.refreshDevicesDisplayed()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:DevicesFidoCell = self.deviceFidoTableview.dequeueReusableCell(withIdentifier: "deviceFidoCell") as! DevicesFidoCell
        cell.friendlyNameText.text = self.devices[indexPath.row].friendlyName
        cell.removeDeviceButton.tag = indexPath.row
        cell.removeDeviceButton.addTarget(self, action: #selector(removeDeviceFido(_:)), for: .touchUpInside)
        
        return cell
    }
    
    @objc func removeDeviceFido(_ sender: UIButton){
        
        AppDelegate.reachfive().deleteWebAuthnRegistration(authToken: self.authToken!,deviceId: self.devices[sender.tag].id)
            .onSuccess {_ in
                self.refreshDevicesDisplayed()
            }
            .onFailure {error in
                self.alertError(error: error)
            }
    }
    
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
    
    @IBAction func addDeviceFido(_ sender: Any) {
        
        AppDelegate.reachfive().addNewWebAuthnDevice(authToken: self.authToken!,origin: AppDelegate.origin,friendlyName: deviceNameText.text,viewController: self)
            .onSuccess {_ in
                self.refreshDevicesDisplayed()
            }
            .onFailure { error in
                self.alertError(error: error)
            }
    }
    
    func refreshDevicesDisplayed()
    {
        AppDelegate.reachfive().listWebAuthnDevices(authToken: self.authToken!).onSuccess { listDevice in
            
            self.devices.removeAll()
            self.devices.append(contentsOf: listDevice)
            
            DispatchQueue.main.async{
                self.deviceFidoTableview.reloadData()
            }
        }
    }
    
    func alertError(error: ReachFiveError)
    {
        var messageAlert = ""
        switch error {
        case .WebauthnError(let webauthnError):
            messageAlert = webauthnError
        case .RequestError(let requestErrors):
            messageAlert = requestErrors.errorDescription!
        case .TechnicalError(_, let apiError):
            messageAlert = (apiError?.errorDescription)! as String
        default:
            messageAlert = error.localizedDescription
        }
        let alert = UIAlertController(title: "Error", message:messageAlert, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
