//
//  PunchInTaskIdViewController.swift
//  BRIZBEE
//
//  Created by Joshua Shane Martin on 8/20/19.
//  Copyright © 2019 East Coast Technology Services, LLC. All rights reserved.
//

import UIKit

class PunchInTaskIdViewController: UIViewController, TaskNumberDelegate {
    var auth: Auth?
    var task: [String: Any]?
    var timeZones: [String]?
    var timeZone: String?
    var user: User?
    
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var taskNumberTextField: UITextField!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.hidesBackButton = true // Hides back button
        
        taskNumberTextField.becomeFirstResponder() // Set focus
    }
    
    // Return to Status View Controller
    @IBAction func onCancelButton(_ sender: Any) {
        if let navigator = self.navigationController {
            navigator.popViewController(animated: true)
        }
    }
    
    @IBAction func onContinueButton(_ sender: Any) {
        self.searchTaskNumber()
    }
    
    @IBAction func onScanButton(_ sender: Any) {
        // Push scan bar code view controller
        let viewController = ScanBarCodeViewController()
        viewController.taskNumberDelegate = self
        if let navigator = self.navigationController {
            navigator.pushViewController(viewController, animated: true)
        }
    }
    
    func searchTaskNumber() {
        self.toggleEnabled(enabled: false) // Disable
        
        if let taskNumber = taskNumberTextField.text {
            if taskNumber.isEmpty {
                // Alert for empty text field
                let alert = UIAlertController(title: "Oops!", message: "You must provide a task number.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    switch action.style{
                    case .default:
                        print("default")
                    case .cancel:
                        print("cancel")
                    case .destructive:
                        print("destructive")
                    @unknown default:
                        print("unknown")
                }}))
                self.present(alert, animated: true, completion: nil)
                self.toggleEnabled(enabled: true)
            }

            // Create the request
            let originalString = String(format: "https://brizbee.gowitheast.com/odata/Tasks?$expand=Job($expand=Customer)&$filter=Number eq '%@'", taskNumber)
            let escapedString = originalString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            let url = URL(string: escapedString!)!
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
                        // Parse JSON
                        if let valueJSON = responseJSON["value"] as? [Any] {
                            if valueJSON.count > 0 {
                                // Task was found
                                self.task = valueJSON.first as? [String: Any]
                                
                                // Push punch in confirm view controller
                                if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Punch In Confirm View Controller") as? PunchInConfirmViewController {
                                    viewController.auth = self.auth
                                    viewController.user = self.user
                                    viewController.task = self.task
                                    viewController.timeZone = self.timeZone
                                    viewController.timeZones = self.timeZones
                                    if let navigator = self.navigationController {
                                        navigator.pushViewController(viewController, animated: true)
                                        
                                        // Clear fields
                                        self.taskNumberTextField.text = ""
                                    }
                                }
                                
                                self.toggleEnabled(enabled: true)
                            } else {
                                self.toggleEnabled(enabled: true)
                            }
                        }
                    }
                }
            }
            
            task.resume()
        }
    }
    
    func taskNumber(taskNumber: String)
    {
        self.taskNumberTextField.text = taskNumber
    }
    
    func toggleEnabled(enabled: Bool) {
        self.loadingIndicator.isHidden = enabled
        
        self.taskNumberTextField.isEnabled = enabled
        self.cancelButton.isEnabled = enabled
        self.continueButton.isEnabled = enabled
        self.scanButton.isEnabled = enabled
    }
}
