//
//  InventoryConfirmViewController.swift
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
//  Created by Joshua Shane Martin on 7/12/21.
//

import UIKit

class InventoryConfirmViewController: UIViewController {
    var auth: Auth?
    var user: User?
    var inventoryItem: QBDInventoryItem?
    var quantity: Int?
    var loadingVC: LoadingViewController?
    var another: Bool = false
    
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var anotherButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var inventoryItemNameLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Update the labels.
        self.inventoryItemNameLabel.text = inventoryItem?.name ?? ""
        self.quantityLabel.text = String(quantity ?? 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the back button.
        navigationItem.hidesBackButton = true
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
            navigator.popToViewController(navigator.viewControllers[1], animated: true)
        }
    }
    
    @IBAction func onAnotherButton(_ sender: UIButton) {
        // Reduce the button opacity.
        sender.alpha = 0.5

        // Return button opacity after delay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            sender.alpha = 1.0
        }
        
        self.another = true
        saveConsumption()
    }
    
    @IBAction func onContinueButton(_ sender: UIButton) {
        // Reduce the button opacity.
        sender.alpha = 0.5

        // Return button opacity after delay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            sender.alpha = 1.0
        }
        
        self.another = false
        saveConsumption()
    }
    
    func saveConsumption() {
        
        // Show loading indicator.
        self.loadingVC = LoadingViewController()
        self.loadingVC!.modalPresentationStyle = .overCurrentContext
        self.loadingVC!.modalTransitionStyle = .crossDissolve
        self.present(loadingVC!, animated: true, completion: nil)
        
        // Prepare the parameters.
        let hostname = UIDevice.current.name
        let unitOfMeasure = ""
        var unitOfMeasureQueryParameter = ""
        
        if unitOfMeasure.count != 0 {
            unitOfMeasureQueryParameter = String(format: "&unitOfMeasure=%@", unitOfMeasure)
        }
        
        // Build the request.
        let originalString = String(format: "https://app-brizbee-prod.azurewebsites.net/api/QBDInventoryConsumptions/Consume?qbdInventoryItemId=%d&quantity=%d&hostname=%@%@", inventoryItem!.id, quantity!, hostname, unitOfMeasureQueryParameter)
        let escapedString = originalString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = URL(string: escapedString!)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
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
                
                let responseData = String(data: data!, encoding: String.Encoding.utf8)
                
                self.handleError(error: responseData)
                
                return
            }
            
            DispatchQueue.main.async {
                guard let navigator = self.navigationController else {
                    
                    // Stop loading indicator.
                    self.loadingVC!.dismiss(animated: true, completion: nil)
                    
                    return
                }
            
                // Dismiss loading indicator and then push.
                self.loadingVC!.dismiss(animated: true, completion: {
                    if (self.another == true) {
                        // Push inventory item.
                        for controller in navigator.viewControllers as Array {
                            if controller.isKind(of: InventoryItemViewController.self) {
                                self.navigationController!.popToViewController(controller, animated: true)
                                break
                            }
                        }
                    } else {
                        // Push status.
                        navigator.popToViewController(navigator.viewControllers[1], animated: true)
                    }
                })
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
}
