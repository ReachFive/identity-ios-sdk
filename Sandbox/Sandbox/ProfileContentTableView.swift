import Foundation
import UIKit
import IdentitySdkCore

struct Field {
    let name: String
    let value: String?
}

// TODO:
// - remove enroll MFA identifier in menu when the identifier has already been enrolled. Requires listMfaCredentials
extension ProfileController {
    
    func format(date: Int) -> String {
        let lastLogin = Date(timeIntervalSince1970: TimeInterval(date / 1000))
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        dateFormatter.locale = Locale(identifier: "en_GB")
        return dateFormatter.string(from: lastLogin)
    }
    
    func updatePhoneNumber(authToken: AuthToken) {
        let alert = UIAlertController(title: "New Phone Number", message: "Please enter the new phone number", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Updated phone number"
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let submitPhoneNumber = UIAlertAction(title: "submit", style: .default) { _ in
            guard let phoneNumber = alert.textFields?[0].text else {
                //TODO alerte
                print("Phone number cannot be empty")
                return
            }
            AppDelegate.reachfive()
                .updatePhoneNumber(authToken: authToken, phoneNumber: phoneNumber)
                .onSuccess { profile in
                    self.present(AppDelegate.createAlert(title: "Update", message: "Update Success"), animated: true)
                }
                .onFailure { error in
                    self.present(AppDelegate.createAlert(title: "Update", message: "Update Error: \(error.message())"), animated: true)
                }
        }
        alert.addAction(cancelAction)
        alert.addAction(submitPhoneNumber)
        present(alert, animated: true)
    }
}

extension ProfileController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ProfileController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return propertiesToDisplay.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("tableView:cellForRowAt:\(indexPath)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDisplayCell", for: indexPath)
        
        var content = cell.defaultContentConfiguration()
        content.text = self.propertiesToDisplay[indexPath.row].name
        content.secondaryText = self.propertiesToDisplay[indexPath.row].value
        content.prefersSideBySideTextAndSecondaryText = true
        
        var textProperties = content.textProperties
        if let customFont = UIFont(name: "system", size: 12) {
            textProperties.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: customFont)
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
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let field = self.propertiesToDisplay[indexPath.row]
        guard let valeur = field.value else {
            return nil
        }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { actions -> UIMenu? in
            var children: [UIMenuElement] = []
            let copy = UIAction(title: "Copy", image: UIImage(systemName: "clipboard")) { action in
                UIPasteboard.general.string = valeur
            }
            children.append(copy)
            // MFA registering button
            if (self.mfaRegistrationAvailable.contains(field.name)) {
                switch field.name {
                case "Email":
                    let mfaRegister = UIAction(title: "Enroll your Email as MFA", image: UIImage(systemName: "key")) { action in
                        guard let authToken = self.authToken else {
                            print("not logged in")
                            return
                        }
//                        self.doMfaEmailRegistration(authToken: authToken)
                    }
                    children.append(mfaRegister)
                default:
                    let mfaRegister = UIAction(title: "Enroll your phone number as MFA", image: UIImage(systemName: "key")) { action in
                        guard let authToken = self.authToken else {
                            print("not logged in")
                            return
                        }
//                        self.doMfaPhoneRegistration(phoneNumber: valeur, authToken: authToken)
                    }
                    
                    children.append(mfaRegister)
                    
                    // Update phone number button
                    let phoneNumberUpdate = UIAction(title: "Update", image: UIImage(systemName: "phone.badge.plus.fill")) { action in
                        self.updatePhoneNumber(authToken: self.authToken!)
                    }
                    children.append(phoneNumberUpdate)
                }
            }
            return UIMenu(title: "Actions", children: children)
        }
    }
}

