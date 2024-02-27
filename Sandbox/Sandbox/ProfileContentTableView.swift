import Foundation
import UIKit
import IdentitySdkCore

struct Field {
    var name: String
    var value: String?
}
// TODO:
// - remove enroll MFA identifier in menu when the identifier has already been enrolled. Requires listMfaCredentials
class ProfileContentTableView: UITableView, UITableViewDataSource, UITableViewDelegate, ProfileRootController {
    var propertiesToDisplay: [Field] = []
    
    var authToken: AuthToken? = nil
    
    let mfaRegistrationAvailable = ["Email", "Phone Number"]
    
    var rootController: UIViewController? {
        return self.window?.rootViewController
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.delegate = self
        self.dataSource = self
    }
        
    func update(profile: Profile, authToken: AuthToken?) {
        self.propertiesToDisplay = [
            Field(name: "Given Name", value: profile.givenName),
            Field(name: "Family Name", value: profile.familyName),
            Field(name: "Email", value: profile.email?.appending(profile.emailVerified == true ? " ✔︎" : " ✘")),
            Field(name: "Phone Number", value: profile.phoneNumber?.appending(profile.phoneNumberVerified == true ? " ✔︎" : " ✘")),
            Field(name: "Custom Identifier", value: profile.customIdentifier),
            Field(name: "Last logged In", value: self.format(date: profile.loginSummary?.lastLogin ?? 0)),
            Field(name: "Method", value: profile.loginSummary?.lastProvider)
        ]
        self.authToken = authToken
    }
    
    private func format(date: Int) -> String {
        let lastLogin = Date(timeIntervalSince1970: TimeInterval(date / 1000))
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        dateFormatter.locale = Locale(identifier: "en_GB")
        return dateFormatter.string(from: lastLogin)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return propertiesToDisplay.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDisplayCell", for: indexPath)

        var content = cell.defaultContentConfiguration()
        content.text = self.propertiesToDisplay[indexPath.row].name
        content.secondaryText = self.propertiesToDisplay[indexPath.row].value
        content.prefersSideBySideTextAndSecondaryText = true
        
        var textProperties = content.textProperties
        if let customFont = UIFont(name: "system", size: 12) {
            textProperties.font = UIFontMetrics(forTextStyle: .body).scaledFont(for:
                customFont)
            textProperties.adjustsFontForContentSizeCategory = true
            textProperties.numberOfLines = 0
        }
        textProperties.adjustsFontSizeToFitWidth = true
        content.textProperties = textProperties
        
        var secondaryTextProperties = content.secondaryTextProperties
        if let secondaryFont = UIFont(name: "system", size: 20) {
            textProperties.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: secondaryFont)
            textProperties.adjustsFontForContentSizeCategory = true
            textProperties.numberOfLines = 0
        }
        secondaryTextProperties.font = UIFont.systemFont(ofSize: 16)
        secondaryTextProperties.adjustsFontSizeToFitWidth = true
        secondaryTextProperties.adjustsFontForContentSizeCategory = true
        content.secondaryTextProperties = secondaryTextProperties
        cell.contentConfiguration = content
                
        return cell
    }
    
    func tableView(_ tableView: UITableView, performPrimaryActionForRowAt indexPath: IndexPath) {
        UIPasteboard.general.string = propertiesToDisplay[indexPath.row].value
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { actions -> UIMenu? in
            let field = self.propertiesToDisplay[indexPath.row]
            var children: [UIMenuElement] = []
            if(field.value != nil) {
                let copy = UIAction(title: "Copy", image: UIImage(systemName: "clipboard" )) { action in
                    UIPasteboard.general.string = field.value
                    let dialogMessage = UIAlertController(title: "Content copied", message: "copied", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                    dialogMessage.addAction(ok)
                    self.rootController?.present(dialogMessage, animated: true)
                }
                children.append(copy)
            }
            /// MFA registering button
            if (self.mfaRegistrationAvailable.contains(field.name)) {
                switch field.name {
                case "Email":
                    let mfaRegister = UIAction(title: "Enroll your Email as MFA", image: UIImage(systemName: "key")) { action in
                        guard let authToken = self.authToken else {
                            print("not logged in")
                            return
                        }
                        self.doMfaEmailRegistration(authToken: authToken)
                    }
                    children.append(mfaRegister)
                default:
                    let mfaRegister = UIAction(title: "Enroll your phone number as MFA", image: UIImage(systemName: "key")) { action in
                        guard let authToken = self.authToken else {
                            print("not logged in")
                            return
                        }
                        guard let phoneNumber = field.value else {
                            print("Phone number cannot be empty")
                            return
                        }
                        self.doMfaPhoneRegistration(phoneNumber: phoneNumber, authToken: authToken)
                    }
                    
                    children.append(mfaRegister)
                    
                    /// Update phone number button
                    let phoneNumberUpdate = UIAction(title: "Update", image: UIImage(systemName: "phone.badge.plus.fill")) { action in
                        self.updatePhoneNumber(authToken: self.authToken)
                    }
                    children.append(phoneNumberUpdate)
                }
            }            
            return UIMenu(title: "More", children: children)
        }
    }
}

