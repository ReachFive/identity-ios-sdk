import UIKit
import IdentitySdkCore

class SignupController: UIViewController {
    @IBOutlet weak var emailInput: UITextField!
    @IBOutlet weak var phoneInput: UITextField!
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var nameInput: UITextField!
    @IBOutlet weak var redirectUrlInput: UITextField!
    var redirectUrl: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AppDelegate.reachfive().initialize().onComplete { _ in }
    }

    @IBAction func signup(_ sender: Any) {
        let email = emailInput.text ?? ""
        let phone = phoneInput.text ?? ""
        let password = passwordInput.text ?? ""
        let name = nameInput.text ?? ""
        
            
        if (!redirectUrlInput.text!.isEmpty)
        {
            redirectUrl = redirectUrlInput.text!
        }
        
        let customFields: [String: CustomField] = [
            "test_string": .string("some random string"),
            "test_integer": .int(1)
        ]
        if (email.isEmpty) && (!phone.isEmpty)
              {
              let profile = ProfileSignupRequest(
                  password: password,
                  phoneNumber:phone,
                  name: name,
                  customFields: customFields
              )
            self.signup(profile:profile)
              }
              else if (!email.isEmpty) && (phone.isEmpty){
                  
                  let profile = ProfileSignupRequest(
                      password: password,
                      email: email,
                      name: name,
                      customFields: customFields
                  )
                self.signup(profile:profile)
              }
              else if ((!email.isEmpty) && (!phone.isEmpty))
              {
                let profile = ProfileSignupRequest(
                    password: password,
                    email: email,
                    phoneNumber: phone,
                    name: name,
                    customFields: customFields
                )
                self.signup(profile:profile)
              }
    }
    
    func goToProfile(_ authToken: AuthToken) {
        AppDelegate.storage.save(key: AppDelegate.authKey, value: authToken)
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let profileController = storyBoard.instantiateViewController(
            withIdentifier: "ProfileScene"
        ) as! ProfileController
        profileController.authToken = authToken
        self.self.navigationController?.pushViewController(profileController, animated: true)
    }
    
    func signup(profile:ProfileSignupRequest)
    {
        AppDelegate.reachfive().signup(profile: profile,redirectUrl: redirectUrl).onSuccess(callback: goToProfile)
    }
}
