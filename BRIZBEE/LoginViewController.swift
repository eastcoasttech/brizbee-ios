//
//  LoginViewController.swift
//  BRIZBEE
//
//  Created by Joshua Shane Martin on 8/20/19.
//  Copyright © 2019 East Coast Technology Services, LLC. All rights reserved.
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.toggleEnabled(enabled: true)
        
        emailOrCodeTextField.becomeFirstResponder() // Set focus
    }

    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            emailOrCodeTextField.placeholder = "Your Organization Code"
            passwordOrPinTextField.placeholder = "Your PIN"
            emailOrCodeTextField.becomeFirstResponder() // set focus
        case 1:
            emailOrCodeTextField.placeholder = "Your Email Address"
            passwordOrPinTextField.placeholder = "Your Password"
            emailOrCodeTextField.becomeFirstResponder() // set focus
        default:
            break;
        }
    }
    
    @IBAction func loginAction(_ sender: UIButton) {
        self.toggleEnabled(enabled: false)
        
        // Prepare json data
        let json: [String: Any] = ["Session": ["Method":"pin",
                                               "PinOrganizationCode":emailOrCodeTextField.text!,
                                               "PinUserPin":passwordOrPinTextField.text!]]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // Create the request
        let url = URL(string: "https://brizbee.gowitheast.com/odata/Users/Default.Authenticate")!
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
        let url = URL(string: String(format: "https://brizbee.gowitheast.com/odata/Users(%@)", self.auth?.userId ?? ""))!
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
                    if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Status View Controller") as? StatusViewController {
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
        let url = URL(string: "https://brizbee.gowitheast.com/odata/Organizations/Default.Timezones")!
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
        self.loadingIndicator.isHidden = enabled
        
        self.emailOrCodeTextField.isEnabled = enabled
        self.passwordOrPinTextField.isEnabled = enabled
        self.segmentedControl.isEnabled = enabled
        self.loginButton.isEnabled = enabled
    }
}
