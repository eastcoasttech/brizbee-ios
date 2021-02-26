//
//  LoginViewController.swift
//  BRIZBEE Mobile for iOS
//
//  Copyright © 2019 East Coast Technology Services, LLC
//
//  This file is part of BRIZBEE Mobile for iOS.
//
//  BRIZBEE Mobile for iOS is free software: you can redistribute
//  it and/or modify it under the terms of the GNU General Public
//  License as published by the Free Software Foundation, either
//  version 3 of the License, or (at your option) any later version.
//
//  BRIZBEE Mobile for iOS is distributed in the hope that it will
//  be useful, but WITHOUT ANY WARRANTY; without even the implied
//  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with BRIZBEE Mobile for iOS.
//  If not, see <https://www.gnu.org/licenses/>.
//
//  Created by Joshua Shane Martin on 8/20/19.
//

import UIKit

class LoginViewController: UIViewController {
    var user: User?
    var auth: Auth?
    var timeZones: [String] = []
    
    @IBOutlet weak var emailOrCodeTextField: UITextField!
    @IBOutlet weak var passwordOrPinTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Adjust scroll position depending on if the keyboard covers the active UIView
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        // Configure placeholders and set focus
        emailOrCodeTextField.attributedPlaceholder = NSAttributedString(string: "Your Organization Code",
                                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        passwordOrPinTextField.attributedPlaceholder = NSAttributedString(string: "Your PIN",
                                                                          attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        emailOrCodeTextField.becomeFirstResponder()
        
        // Set padding
        let paddingView1: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: self.emailOrCodeTextField.frame.height))
        emailOrCodeTextField.leftView = paddingView1
        emailOrCodeTextField.leftViewMode = .always
        
        let paddingView2: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: self.emailOrCodeTextField.frame.height))
        passwordOrPinTextField.leftView = paddingView2
        passwordOrPinTextField.leftViewMode = .always
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reset the view
        self.toggleEnabled(enabled: true)
        
        // Tap outside of keyboard will dismiss
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
        
        // Add a done button to the keyboard toolbar
        let barKeyboard = UIToolbar()
        barKeyboard.sizeToFit()
        let btnKeyboardDone = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.doneBtnFromKeyboardClicked))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        barKeyboard.items = [flexibleSpace, btnKeyboardDone]
        emailOrCodeTextField.inputAccessoryView = barKeyboard
        passwordOrPinTextField.inputAccessoryView = barKeyboard
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove keyboard observers when finished
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func doneBtnFromKeyboardClicked(_ sender: UIButton) {
        self.view.endEditing(true)
    }

    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            // Configure placeholder and set focus
            emailOrCodeTextField.attributedPlaceholder = NSAttributedString(string: "Your Organization Code",
                                                                            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            passwordOrPinTextField.attributedPlaceholder = NSAttributedString(string: "Your PIN",
                                                                              attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            emailOrCodeTextField.becomeFirstResponder()
        case 1:
            // Configure placeholder and set focus
            emailOrCodeTextField.attributedPlaceholder = NSAttributedString(string: "Your Email Address",
                                                                            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            passwordOrPinTextField.attributedPlaceholder = NSAttributedString(string: "Your Password",
                                                                              attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            emailOrCodeTextField.becomeFirstResponder()
        default:
            break;
        }
    }
    
    @IBAction func loginAction(_ sender: UIButton) {
        
        // Do not continue without any credentials
        if (!emailOrCodeTextField.hasText || !passwordOrPinTextField.hasText) {
            return;
        }
        
        self.toggleEnabled(enabled: false)
        
        // Prepare json data
        let json: [String: Any] = ["Session": ["Method": "pin",
                                               "PinOrganizationCode": emailOrCodeTextField.text!,
                                               "PinUserPin": passwordOrPinTextField.text!]]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // Create the request
        let url = URL(string: "https://app-brizbee-prod.azurewebsites.net/odata/Users/Default.Authenticate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add json data to the body
        request.httpBody = jsonData
        
        // Send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                self.toggleEnabled(enabled: true)
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                DispatchQueue.main.async {
                    // Parse JSON for authentication headers
                    let token = responseJSON["AuthToken"] as? String ?? ""
                    let expiration = responseJSON["AuthExpiration"] as? String ?? ""
                    let userId = responseJSON["AuthUserId"] as? String ?? ""
                    self.auth = Auth(token: token, userId: userId, expiration: expiration)
                    
                    // Load the time zones
                    self.loadTimeZones()
                    
                    // Load the authenticated user's details
                    self.loadUser()
                }
            }
        }
        
        task.resume()
    }
    
    func loadUser() {
        // Create the request
        let url = URL(string: String(format: "https://app-brizbee-prod.azurewebsites.net/odata/Users(%@)", self.auth?.userId ?? ""))!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Set the headers
        request.addValue(auth?.token ?? "", forHTTPHeaderField: "AUTH_TOKEN")
        request.addValue(auth?.userId ?? "", forHTTPHeaderField: "AUTH_USER_ID")
        request.addValue(auth?.expiration ?? "", forHTTPHeaderField: "AUTH_EXPIRATION")
        
        // Send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                DispatchQueue.main.async {
                    // Parse JSON for user details
                    let nameString = responseJSON["Name"] as? String ?? ""
                    let emailString = responseJSON["EmailAddress"] as? String ?? ""
                    let idString = responseJSON["Id"] as? String ?? ""
                    let timeZoneString = responseJSON["TimeZone"] as? String ?? ""
                    self.user = User(name: nameString, emailAddress: emailString, id: idString, timeZone: timeZoneString)

                    // Push status view controller
                    if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Status Staging View Controller") as? StatusStagingViewController {
                        viewController.auth = self.auth
                        viewController.user = self.user
                        viewController.timeZones = self.timeZones
                        if let navigator = self.navigationController {
                            navigator.pushViewController(viewController, animated: true)
                            
                            // Clear login fields
                            self.emailOrCodeTextField.text = ""
                            self.passwordOrPinTextField.text = ""
                        }
                    }
                }
            }
        }
        
        task.resume()
    }
    
    func loadTimeZones() {
        // Create the request
        let url = URL(string: "https://app-brizbee-prod.azurewebsites.net/odata/Organizations/Default.Timezones")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Set the headers
        request.addValue(auth?.token ?? "", forHTTPHeaderField: "AUTH_TOKEN")
        request.addValue(auth?.userId ?? "", forHTTPHeaderField: "AUTH_USER_ID")
        request.addValue(auth?.expiration ?? "", forHTTPHeaderField: "AUTH_EXPIRATION")
        
        // Send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                let valueJSON = responseJSON["value"] as? [Any]
                for item in valueJSON! {
                    if let itemJSON = item as? [String: Any] {
                        if let id = itemJSON["Id"] as? String {
                            self.timeZones.append(id)
                        }
                    }
                }
            }
        }
        
        task.resume()
    }
    
    func toggleEnabled(enabled: Bool) {
        if (enabled) {
            loadingIndicator.stopAnimating()
        } else {
            loadingIndicator.startAnimating()
        }
        loadingIndicator.isHidden = enabled
        
        emailOrCodeTextField.isEnabled = enabled
        passwordOrPinTextField.isEnabled = enabled
        segmentedControl.isEnabled = enabled
        loginButton.isEnabled = enabled
    }

    // Stored values for resetting the scroll position
    var scrollOffset : CGFloat = 0
    var distance : CGFloat = 0
    
    // Move the scroll position to accomodate the keyboard if it is necessary
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            var safeArea = self.view.frame
            safeArea.size.height += scrollView.contentOffset.y
            safeArea.size.height -= keyboardSize.height + (UIScreen.main.bounds.height*0.24) // Adjust buffer

            // Determine which UIView was made active and if it is covered by keyboard
            let activeField: UIView? = [emailOrCodeTextField, passwordOrPinTextField].first { $0.isFirstResponder }
            if let activeField = activeField {
                if safeArea.contains(CGPoint(x: 0, y: activeField.frame.maxY)) {
                    // No need to scroll
                    return
                } else {
                    distance = activeField.frame.maxY - safeArea.size.height
                    scrollOffset = scrollView.contentOffset.y
                    self.scrollView.setContentOffset(CGPoint(x: 0, y: scrollOffset + distance), animated: true)
                }
            }

            // Prevent scrolling while typing
            scrollView.isScrollEnabled = false
        }
    }
    
    // Move the scroll position to the original position
    @objc func keyboardWillHide(notification: NSNotification) {
        if distance == 0 {
            return
        }
        // return to origin scrollOffset
        self.scrollView.setContentOffset(CGPoint(x: 0, y: scrollOffset), animated: true)
        scrollOffset = 0
        distance = 0
        scrollView.isScrollEnabled = true
    }
}
