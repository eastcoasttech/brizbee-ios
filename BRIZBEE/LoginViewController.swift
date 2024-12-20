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
    var loadingVC: LoadingViewController?
    
    @IBOutlet weak var emailOrCodeTextField: UITextField!
    @IBOutlet weak var passwordOrPinTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var logoView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Programmatically set the font size of the segmented control for iPad.
        if UIDevice.current.userInterfaceIdiom == .pad {
            let font = UIFont.systemFont(ofSize: 20)
            segmentedControl.setTitleTextAttributes([NSAttributedString.Key.font: font], for: .normal)
        }
        
        // Adjust scroll position depending on if the keyboard covers the active UIView
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        // Configure placeholders and set focus
        emailOrCodeTextField.attributedPlaceholder = NSAttributedString(string: "Your Organization Code",
                                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        passwordOrPinTextField.attributedPlaceholder = NSAttributedString(string: "Your PIN",
                                                                          attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        // Set padding.
        let paddingView1: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: self.emailOrCodeTextField.frame.height))
        self.emailOrCodeTextField.leftView = paddingView1
        self.emailOrCodeTextField.leftViewMode = .always
        
        let paddingView2: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: self.emailOrCodeTextField.frame.height))
        self.passwordOrPinTextField.leftView = paddingView2
        self.passwordOrPinTextField.leftViewMode = .always
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Tap outside of keyboard will dismiss
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
        
        // Add a done button to the keyboard toolbar
        let barKeyboard = UIToolbar()
        barKeyboard.sizeToFit()
        let btnKeyboardDone = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.doneBtnFromKeyboardClicked))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        barKeyboard.items = [flexibleSpace, btnKeyboardDone]
        self.emailOrCodeTextField.inputAccessoryView = barKeyboard
        self.passwordOrPinTextField.inputAccessoryView = barKeyboard
        
        // Set focus.
        self.emailOrCodeTextField.becomeFirstResponder()
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
            emailOrCodeTextField.placeholder = "Your Organization Code"
            passwordOrPinTextField.placeholder = "Your PIN"
            emailOrCodeTextField.becomeFirstResponder()
        case 1:
            // Configure placeholder and set focus
            emailOrCodeTextField.placeholder = "Your Email Address"
            passwordOrPinTextField.placeholder = "Your Password"
            emailOrCodeTextField.becomeFirstResponder()
        default:
            break;
        }
    }
    
    @IBAction func loginAction(_ sender: UIButton) {
        // Reduce the button opacity.
        sender.alpha = 0.5

        // Return button opacity after delay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            sender.alpha = 1.0
        }
        
        // Do not continue if blank.
        if (!emailOrCodeTextField.hasText || !passwordOrPinTextField.hasText) {
            return;
        }
        
        // Hide toolbar.
        self.view.endEditing(true)
        
        // Show loading indicator.
        self.loadingVC = LoadingViewController()
        self.loadingVC!.modalPresentationStyle = .overCurrentContext
        self.loadingVC!.modalTransitionStyle = .crossDissolve
        self.present(loadingVC!, animated: true, completion: nil)
        
        // Prepare payload.
        let json: [String: Any] = ["Method": "pin",
                                   "PinOrganizationCode": emailOrCodeTextField.text!,
                                   "PinUserPin": passwordOrPinTextField.text!]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // Build the request.
        let url = URL(string: "\(Constants.baseUrl)/api/Auth/Authenticate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add payload to the request body.
        request.httpBody = jsonData
        
        // Send the request.
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                
                self.handleError(error: error.localizedDescription)
                
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                
                var responseData = String(data: data!, encoding: String.Encoding.utf8)
                
                if (response as? HTTPURLResponse)?.statusCode == 400 {
                    responseData = "Invalid organization code and user pin."
                }
                
                self.handleError(error: responseData)
                
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data!, options: [])
            if let json = json as? [String: Any] {
                
                // Parse JSON for authentication headers.
                let token = json["token"] as? String ?? ""
                self.auth = Auth(token: token)
                
                // Load the time zones.
                self.loadTimeZones()
                
                // Load the user details.
                self.loadUser()
            }
        }
        
        task.resume()
    }
    
    func loadUser() {
        // Build the request.
        let url = URL(string: "\(Constants.baseUrl)/api/Auth/Me")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Set the headers.
        if auth != nil {
            request.addValue("Bearer \(auth!.token)", forHTTPHeaderField: "Authorization")
        }
        
        // Send the request.
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                
                self.handleError(error: error.localizedDescription)
                
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                
                let responseData = String(data: data!, encoding: String.Encoding.utf8)
                
                self.handleError(error: responseData)
                
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data!, options: [])
            if let json = json as? [String: Any] {
                
                // Parse the response.
                let nameString = json["name"] as? String ?? ""
                let emailString = json["emailAddress"] as? String ?? ""
                let idString = json["id"] as? String ?? ""
                let timeZoneString = json["timeZone"] as? String ?? ""
                let usesTimeCards = json["usesTimesheets"] as? Bool ?? false
                let usesMobileApp = json["usesMobileClock"] as? Bool ?? false
                let requiresLocation = json["requiresLocation"] as? Bool ?? false
                self.user = User(name: nameString,
                                 emailAddress: emailString,
                                 id: idString,
                                 timeZone: timeZoneString,
                                 usesMobileApp: usesMobileApp,
                                 usesTimeCards: usesTimeCards,
                                 requiresLocation: requiresLocation)
                
                // Check if the user is allowed to use the mobile app.
                if (usesMobileApp == false) {
                    
                    DispatchQueue.main.async {
                        
                        // Dismiss loading indicator and then alert.
                        self.loadingVC!.dismiss(animated: true, completion: {
                            let alert = UIAlertController(title: "Oops!",
                                                          message: "You are not allowed to use the mobile app. Please contact your administrator.",
                                                          preferredStyle: .alert)
                            let alertOKAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
                            alert.addAction(alertOKAction)
                            self.present(alert, animated: true, completion:nil)
                        })
                    }
                    
                    return
                }
                
                // Push staging view controller.
                let stagingVC: StatusStagingViewController?
                
                switch UIDevice.current.userInterfaceIdiom {
                    case .pad:
                        stagingVC = UIStoryboard(name: "Main iPad", bundle: nil).instantiateViewController(withIdentifier: "Status Staging View Controller") as? StatusStagingViewController
                    default:
                        stagingVC = UIStoryboard(name: "Main iPhone", bundle: nil).instantiateViewController(withIdentifier: "Status Staging View Controller") as? StatusStagingViewController
                }
                
                stagingVC!.auth = self.auth
                stagingVC!.user = self.user
                stagingVC!.timeZones = self.timeZones
                
                DispatchQueue.main.async {
                    
                    if let navigator = self.navigationController {
                        
                        // Dismiss loading indicator and then push.
                        self.loadingVC!.dismiss(animated: true, completion: {
                            navigator.pushViewController(stagingVC!, animated: true)
                            
                            // Clear fields.
                            self.emailOrCodeTextField.text = ""
                            self.passwordOrPinTextField.text = ""
                        })
                    }
                }
            }
        }
        
        task.resume()
    }
    
    func loadTimeZones() {
        // Build the request.
        let url = URL(string: "\(Constants.baseUrl)/api/Kiosk/TimeZones")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Set the headers.
        if auth != nil {
            request.addValue("Bearer \(auth!.token)", forHTTPHeaderField: "Authorization")
        }
        
        // Send the request.
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                
                self.handleError(error: error.localizedDescription)
                
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                
                let responseData = String(data: data!, encoding: String.Encoding.utf8)
                
                self.handleError(error: responseData)
                
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data!, options: [])
            if let json = json as? [Any] {
                for item in json {
                    if let itemJSON = item as? [String: Any] {
                        if let id = itemJSON["id"] as? String {
                            self.timeZones.append(id)
                        }
                    }
                }
            }
        }
        
        task.resume()
    }
    
    func handleError(error: String?) {
        
        DispatchQueue.main.async {
            
            // Dismiss loading indicator and then alert.
            self.loadingVC!.dismiss(animated: true, completion: {
                let alert = UIAlertController(title: "Oops!",
                                              message: error,
                                              preferredStyle: .alert)
                let alertOKAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
                alert.addAction(alertOKAction)
                self.present(alert, animated: true, completion:nil)
            })
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if (self.traitCollection.userInterfaceStyle == .dark) {
                print("Entered dark mode")
            } else {
                print("Entered light mode")
            }
        }
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
