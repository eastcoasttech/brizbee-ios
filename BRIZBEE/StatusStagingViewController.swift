//
//  StatusStagingViewController.swift
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

class StatusStagingViewController: UIViewController {
    var auth: Auth?
    var user: User?
    var timeZones: [String]?
    var timeZone: String?
    var currentTask: String?
    var currentJob: String?
    var currentCustomer: String?
    var currentSince: String?
    var currentSinceTimeZone: String?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the back button.
        navigationItem.hidesBackButton = true
        
        self.loadCurrentPunch()
    }
    
    func loadCurrentPunch() {
        
        // Build the URL.
        var components = URLComponents()
        components.scheme = Constants.scheme
        components.host = Constants.host
        components.path = "/api/Kiosk/Punches/Current"
        
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
                (200...299).contains(httpResponse.statusCode) else {
                
                let responseData = String(data: data!, encoding: String.Encoding.utf8)
                
                self.handleError(error: responseData)
                
                return
            }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data!, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                
                // Check for a response.
                if (responseJSON.isEmpty) {
                    
                    DispatchQueue.main.async {
                        
                        // User is punched out and will be pushed to status out view controller.
                        let statusOutVC: StatusOutViewController?
                        
                        switch UIDevice.current.userInterfaceIdiom {
                            case .pad:
                            statusOutVC = UIStoryboard(name: "Main iPad", bundle: nil).instantiateViewController(withIdentifier: "Status Out View Controller") as? StatusOutViewController
                            default:
                            statusOutVC = UIStoryboard(name: "Main iPhone", bundle: nil).instantiateViewController(withIdentifier: "Status Out View Controller") as? StatusOutViewController
                        }
                        
                        statusOutVC!.auth = self.auth
                        statusOutVC!.user = self.user
                        statusOutVC!.timeZone = self.timeZone
                        statusOutVC!.timeZones = self.timeZones
                        if let navigator = self.navigationController {
                            navigator.pushViewController(statusOutVC!, animated: true)
                        }
                    }
                    
                    return
                }
                
                // Since
                let inAt = responseJSON["inAt"] as? String ?? ""
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
                let date = dateFormatter.date(from:inAt)!
                
                let humanFormatter = DateFormatter()
                humanFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                humanFormatter.dateFormat = "MMM dd, yyyy h:mm a"
                humanFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
                let humanString = humanFormatter.string(from: date)
                
                
                // Since Time Zone
                let inAtTimeZone = responseJSON["inAtTimeZone"] as? String ?? ""
                
                // Task
                let task = responseJSON["task"] as? [String: Any]
                let taskNumber = task?["number"] as? String ?? ""
                let taskName = task?["name"] as? String ?? ""
                let taskString = String(format: "%@ - %@", taskNumber, taskName)
                
                // Job
                let job = task?["job"] as? [String: Any]
                let jobNumber = job?["number"] as? String ?? ""
                let jobName = job?["name"] as? String ?? ""
                let jobString = String(format: "%@ - %@", jobNumber, jobName)
                
                // Customer
                let customer = job?["customer"] as? [String: Any]
                let customerNumber = customer?["number"] as? String ?? ""
                let customerName = customer?["name"] as? String ?? ""
                let customerString = String(format: "%@ - %@", customerNumber, customerName)
                
                DispatchQueue.main.async {
                    
                    // Update user interface on the main thread.
                    self.currentSince = humanString
                    self.currentSinceTimeZone = inAtTimeZone
                    self.timeZone = inAtTimeZone // Use this time zone to punch in or out later
                    self.currentTask = taskString
                    self.currentJob = jobString
                    self.currentCustomer = customerString
                    
                    // User is punched in and will be pushed to status in view controller.
                    let statusInVC: StatusInViewController?
                    
                    switch UIDevice.current.userInterfaceIdiom {
                        case .pad:
                        statusInVC = UIStoryboard(name: "Main iPad", bundle: nil).instantiateViewController(withIdentifier: "Status In View Controller") as? StatusInViewController
                        default:
                        statusInVC = UIStoryboard(name: "Main iPhone", bundle: nil).instantiateViewController(withIdentifier: "Status In View Controller") as? StatusInViewController
                    }
                    
                    statusInVC!.auth = self.auth
                    statusInVC!.user = self.user
                    statusInVC!.timeZone = self.timeZone
                    statusInVC!.timeZones = self.timeZones
                    statusInVC!.currentSince = self.currentSince
                    statusInVC!.currentSinceTimeZone = self.currentSinceTimeZone
                    statusInVC!.currentTask = self.currentTask
                    statusInVC!.currentJob = self.currentJob
                    statusInVC!.currentCustomer = self.currentCustomer
                    if let navigator = self.navigationController {
                        navigator.pushViewController(statusInVC!, animated: true)
                    }
                }
            }
        }
        
        task.resume()
    }
    
    func handleError(error: String?) {
        
        DispatchQueue.main.async {
            
            let alert = UIAlertController(title: "Oops!",
                                          message: error,
                                          preferredStyle: .alert)
            let alertOKAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {
                action in self.okAlert(action, alert)
            })
            alert.addAction(alertOKAction)
            self.present(alert, animated: true, completion: nil)
            
        }
    }
    
    func okAlert(_ action: UIAlertAction, _ alert:UIAlertController) {
        
        // Pop to login.
        if let navigator = self.navigationController {
            navigator.popViewController(animated: true)
        }
    }
}
