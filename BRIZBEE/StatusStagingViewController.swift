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
    var statusOutVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Status Out View Controller") as? StatusOutViewController
    var statusInVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Status In View Controller") as? StatusInViewController
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
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
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data!, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                
                // Check for a response.
                if (responseJSON.isEmpty) {
                    
                    DispatchQueue.main.async {
                        
                        // User is punched out and will be pushed to status out.
                        self.statusOutVC!.auth = self.auth
                        self.statusOutVC!.user = self.user
                        self.statusOutVC!.timeZone = self.timeZone
                        self.statusOutVC!.timeZones = self.timeZones
                        if let navigator = self.navigationController {
                            navigator.pushViewController(self.statusOutVC!, animated: true)
                        }
                    }
                    
                    return
                }
                
                // Since
                let inAt = responseJSON["InAt"] as? String ?? ""
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
                let date = dateFormatter.date(from:inAt)!
                
                let humanFormatter = DateFormatter()
                humanFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                humanFormatter.dateFormat = "MMM dd, yyyy h:mm a"
                humanFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
                let humanString = humanFormatter.string(from: date)
                
                self.currentSince = humanString
                
                // Since Time Zone
                let inAtTimeZone = responseJSON["InAtTimeZone"] as? String ?? ""
                self.currentSinceTimeZone = inAtTimeZone
                
                // Use this time zone to punch in or out later
                self.timeZone = inAtTimeZone
                
                // Task
                let task = responseJSON["Task"] as? [String: Any]
                let taskNumber = task?["Number"] as? String ?? ""
                let taskName = task?["Name"] as? String ?? ""
                let taskString = String(format: "%@ - %@", taskNumber, taskName)
                self.currentTask = taskString
                
                // Job
                let job = task?["Job"] as? [String: Any]
                let jobNumber = job?["Number"] as? String ?? ""
                let jobName = job?["Name"] as? String ?? ""
                let jobString = String(format: "%@ - %@", jobNumber, jobName)
                self.currentJob = jobString
                
                // Customer
                let customer = job?["Customer"] as? [String: Any]
                let customerNumber = customer?["Number"] as? String ?? ""
                let customerName = customer?["Name"] as? String ?? ""
                let customerString = String(format: "%@ - %@", customerNumber, customerName)
                self.currentCustomer = customerString
                
                DispatchQueue.main.async {
                    
                    // User is punched in and will be pushed to status in.
                    self.statusInVC!.auth = self.auth
                    self.statusInVC!.user = self.user
                    self.statusInVC!.timeZone = self.timeZone
                    self.statusInVC!.timeZones = self.timeZones
                    self.statusInVC!.currentSince = self.currentSince
                    self.statusInVC!.currentSinceTimeZone = self.currentSinceTimeZone
                    self.statusInVC!.currentTask = self.currentTask
                    self.statusInVC!.currentJob = self.currentJob
                    self.statusInVC!.currentCustomer = self.currentCustomer
                    if let navigator = self.navigationController {
                        navigator.pushViewController(self.statusInVC!, animated: true)
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
