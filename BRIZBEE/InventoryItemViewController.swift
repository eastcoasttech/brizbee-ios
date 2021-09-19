//
//  InventoryItemViewController.swift
//  BRIZBEE Mobile for iOS
//
//  Copyright © 2019-2021 East Coast Technology Services, LLC
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
//  Created by Joshua Shane Martin on 7/11/21.
//

import UIKit

class InventoryItemViewController: UIViewController, TaskNumberDelegate {
    var auth: Auth?
    var user: User?
    var inventoryItem: QBDInventoryItem?
    var loadingVC: LoadingViewController?
    var quantityVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Inventory Quantity View Controller") as? InventoryQuantityViewController
    
    @IBOutlet weak var barCodeValueTextField: UITextField!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Adjust scroll position depending on if the keyboard covers the active UIView.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the back button.
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
        barCodeValueTextField.inputAccessoryView = barKeyboard
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Search for the bar code value that was provided from the barcode.
        if (self.barCodeValueTextField.text?.count ?? 0 > 0) {
            self.searchInventoryItem()
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
        
        self.searchInventoryItem()
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
    
    func taskNumber(taskNumber: String) {
        self.barCodeValueTextField.text = taskNumber
    }
    
    func searchInventoryItem() {
        
        // Hide toolbar.
        self.view.endEditing(true)
        
        // Do not continue if blank.
        if (!barCodeValueTextField.hasText) {
            
            let alert = UIAlertController(title: "Oops!",
                                          message: "You must provide a bar code value.",
                                          preferredStyle: .alert)
            let alertOKAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
            alert.addAction(alertOKAction)
            self.present(alert, animated: true, completion:nil)
            
            return;
        }
        
        // Show loading indicator.
        self.loadingVC = LoadingViewController()
        self.loadingVC!.modalPresentationStyle = .overCurrentContext
        self.loadingVC!.modalTransitionStyle = .crossDissolve
        self.present(loadingVC!, animated: true, completion: nil)
        
        let barCodeValue = barCodeValueTextField.text!
        
        // Build the URL.
        var components = URLComponents()
        components.scheme = Constants.scheme
        components.host = Constants.host
        components.path = "/api/Kiosk/InventoryItems/Search"

        components.queryItems = [
            URLQueryItem(name: "barCodeValue", value: barCodeValue)
        ]
        
        // Build the request.
        let url = URL(string: components.string!)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Set the headers.
        request.addValue(auth?.token ?? "", forHTTPHeaderField: "AUTH_TOKEN")
        request.addValue(auth?.userId ?? "", forHTTPHeaderField: "AUTH_USER_ID")
        request.addValue(auth?.expiration ?? "", forHTTPHeaderField: "AUTH_EXPIRATION")

        // Send the request.
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                
                self.handleError(error: error.localizedDescription)
                
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                
                var responseData = String(data: data!, encoding: String.Encoding.utf8)
                
                if (response as? HTTPURLResponse)?.statusCode == 404 {
                    responseData = "No item matches that bar code value."
                }
                
                self.handleError(error: responseData)
                
                return
            }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data!, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                
                // Parse the response.
                let idInt = responseJSON["Id"] as? Int64 ?? 0
                let fullNameString = responseJSON["FullName"] as? String ?? ""
                let barCodeValueString = responseJSON["BarCodeValue"] as? String ?? ""
                let listIdString = responseJSON["ListId"] as? String ?? ""
                let nameString = responseJSON["Name"] as? String ?? ""
                let manufacturerPartNumberString = responseJSON["ManufacturerPartNumber"] as? String ?? ""
                let purchaseCostString = responseJSON["PurchaseCost"] as? String ?? ""
                let purchaseDescriptionString = responseJSON["PurchaseDescription"] as? String ?? ""
                let salesPriceString = responseJSON["SalesPrice"] as? String ?? ""
                let salesDescriptionString = responseJSON["SalesDescription"] as? String ?? ""
                
                self.inventoryItem = QBDInventoryItem(id: idInt, fullName: fullNameString, barCodeValue: barCodeValueString, listId: listIdString, name: nameString, manufacturerPartNumber: manufacturerPartNumberString, purchaseCost: purchaseCostString, purchaseDescription: purchaseDescriptionString, salesPrice: salesPriceString, salesDescription: salesDescriptionString)
                
                DispatchQueue.main.async {
                    
                    // Push quantity.
                    self.quantityVC!.auth = self.auth
                    self.quantityVC!.user = self.user
                    self.quantityVC!.inventoryItem = self.inventoryItem
                    if let navigator = self.navigationController {
                        
                        // Clear fields now instead of when appearing.
                        self.barCodeValueTextField.text = ""
                        
                        // Dismiss loading indicator and then push.
                        self.loadingVC!.dismiss(animated: true, completion: {
                            navigator.pushViewController(self.quantityVC!, animated: true)
                        })
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
    
    // Stored values for resetting the scroll position.
    var scrollOffset : CGFloat = 0
    var distance : CGFloat = 0
    
    // Move the scroll position to accomodate the keyboard if it is necessary.
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {

            var safeArea = self.view.frame
            safeArea.size.height += scrollView.contentOffset.y
            safeArea.size.height -= keyboardSize.height + (UIScreen.main.bounds.height*0.24) // Adjust buffer

            // Determine which UIView was made active and if it is covered by keyboard
            let activeField: UIView? = [barCodeValueTextField].first { $0.isFirstResponder }
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
