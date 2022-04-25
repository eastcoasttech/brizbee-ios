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
    var loadingVC: LoadingViewController?
    var confirmVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Punch In Confirm View Controller") as? PunchInConfirmViewController
    
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var taskNumberTextField: UITextField!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Adjust scroll position depending on if the keyboard covers the active UIView.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the back button
        navigationItem.hidesBackButton = true
        
        // Tap outside of keyboard will dismiss.
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
        
        // Add a done button to the keyboard toolbar.
        let barKeyboard = UIToolbar()
        barKeyboard.sizeToFit()
        let btnKeyboardDone = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.doneBtnFromKeyboardClicked))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        barKeyboard.items = [flexibleSpace, btnKeyboardDone]
        taskNumberTextField.inputAccessoryView = barKeyboard
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Search for the task number that was provided from the barcode.
        if (self.taskNumberTextField.text?.count ?? 0 > 0) {
            self.searchTaskNumber()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove keyboard observers when finished.
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func doneBtnFromKeyboardClicked(_ sender: UIButton) {
        self.view.endEditing(true)
    }
    
    @IBAction func onCancelButton(_ sender: UIButton) {
        // Reduce the button opacity.
        sender.alpha = 0.5

        // Return button opacity after delay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            sender.alpha = 1.0
        }
        
        // Return to previous.
        if let navigator = self.navigationController {
            navigator.popViewController(animated: true)
        }
    }
    
    @IBAction func onContinueButton(_ sender: UIButton) {
        // Reduce the button opacity.
        sender.alpha = 0.5

        // Return button opacity after delay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            sender.alpha = 1.0
        }
        
        self.searchTaskNumber()
    }
    
    @IBAction func onScanButton(_ sender: UIButton) {
        // Reduce the button opacity.
        sender.alpha = 0.5

        // Return button opacity after delay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            sender.alpha = 1.0
        }
        
        // Push scan bar code.
        let viewController = ScanBarCodeViewController()
        viewController.taskNumberDelegate = self
        if let navigator = self.navigationController {
            navigator.pushViewController(viewController, animated: true)
        }
    }
    
    func searchTaskNumber() {
        
        // Hide toolbar.
        self.view.endEditing(true)
        
        // Do not continue if blank.
        if (!taskNumberTextField.hasText) {
            let alert = UIAlertController(title: "Oops!",
                                          message: "You must provide a task number.",
                                          preferredStyle: .alert)
            let alertOKAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
            alert.addAction(alertOKAction)
            self.present(alert, animated: true, completion:nil)
            
            return
        }
        
        // Show loading indicator.
        self.loadingVC = LoadingViewController()
        self.loadingVC!.modalPresentationStyle = .overCurrentContext
        self.loadingVC!.modalTransitionStyle = .crossDissolve
        self.present(loadingVC!, animated: true, completion: nil)
        
        let taskNumber = taskNumberTextField.text!
        
        // Build the URL.
        var components = URLComponents()
        components.scheme = Constants.scheme
        components.host = Constants.host
        components.path = "/api/Kiosk/SearchTasks"

        components.queryItems = [
            URLQueryItem(name: "taskNumber", value: taskNumber)
        ]
        
        // Build the request.
        let url = URL(string: components.string!)!
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
                  // TODO handle 404!
                (200...299).contains(httpResponse.statusCode) else {
                
                let responseData = String(data: data!, encoding: String.Encoding.utf8)
                
                self.handleError(error: responseData)
                
                return
            }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data!, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                
                // Parse the response.
                self.task = responseJSON
                
                DispatchQueue.main.async {
                    
                    // Push confirm.
                    self.confirmVC!.auth = self.auth
                    self.confirmVC!.user = self.user
                    self.confirmVC!.task = self.task
                    self.confirmVC!.timeZone = self.timeZone
                    self.confirmVC!.timeZones = self.timeZones
                    if let navigator = self.navigationController {
                        
                        // Clear fields now instead of when appearing.
                        self.taskNumberTextField.text = ""
                        
                        // Dismiss loading indicator and then push.
                        self.loadingVC!.dismiss(animated: true, completion: {
                            navigator.pushViewController(self.confirmVC!, animated: true)
                        })
                    }
                }
            }
        }
        
        task.resume()
    }
    
    func taskNumber(taskNumber: String) {
        self.taskNumberTextField.text = taskNumber
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
