//
//  PunchInTaskIdViewController.swift
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
import AVFoundation

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
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Adjust scroll position depending on if the keyboard covers the active UIView
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        // Configure placeholder
        taskNumberTextField.attributedPlaceholder = NSAttributedString(string: "00000",
                                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Must stop by default because it will be displayed
        loadingIndicator.stopAnimating()
        
        // Hide the back button
        navigationItem.hidesBackButton = true
        
        // Tap outside of keyboard will dismiss
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
        
        // Add a done button to the keyboard toolbar
        let barKeyboard = UIToolbar()
        barKeyboard.sizeToFit()
        let btnKeyboardDone = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.doneBtnFromKeyboardClicked))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        barKeyboard.items = [flexibleSpace, btnKeyboardDone]
        taskNumberTextField.inputAccessoryView = barKeyboard
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove keyboard observers when finished
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func doneBtnFromKeyboardClicked(_ sender: UIButton) {
        self.view.endEditing(true)
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
            let originalString = String(format: "https://app-brizbee-prod.azurewebsites.net/odata/Tasks?$expand=Job($expand=Customer)&$filter=Number eq '%@'", taskNumber)
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
        if (enabled) {
            loadingIndicator.stopAnimating()
        } else {
            loadingIndicator.startAnimating()
        }
        loadingIndicator.isHidden = enabled
        
        taskNumberTextField.isEnabled = enabled
        cancelButton.isEnabled = enabled
        continueButton.isEnabled = enabled
        scanButton.isEnabled = enabled
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
            let activeField: UIView? = [taskNumberTextField].first { $0.isFirstResponder }
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
