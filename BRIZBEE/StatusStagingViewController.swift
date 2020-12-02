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
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Prevent going back
        navigationItem.hidesBackButton = true
        
        self.loadCurrentPunch()
    }
    
    func loadCurrentPunch() {
        // Create the request
        let url = URL(string: "https://brizbee.gowitheast.com/odata/Punches/Default.Current?$expand=Task($expand=Job($expand=Customer))")!
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
                            // User is punched in
                            
                            let valueFirstJSON = valueJSON.first as? [String: Any]
                            
                            // Since
                            let inAt = valueFirstJSON?["InAt"] as? String ?? ""
                            
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
                            let inAtTimeZone = valueFirstJSON?["InAtTimeZone"] as? String ?? ""
                            self.currentSinceTimeZone = inAtTimeZone
                            
                            // Use this time zone to punch in or out later
                            self.timeZone = inAtTimeZone
                            
                            // Task
                            let task = valueFirstJSON?["Task"] as? [String: Any]
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
                            
                            // Go to in status view
                            if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Status In View Controller") as? StatusInViewController {
                                viewController.auth = self.auth
                                viewController.user = self.user
                                viewController.timeZone = self.timeZone
                                viewController.timeZones = self.timeZones
                                viewController.currentSince = self.currentSince
                                viewController.currentSinceTimeZone = self.currentSinceTimeZone
                                viewController.currentTask = self.currentTask
                                viewController.currentJob = self.currentJob
                                viewController.currentCustomer = self.currentCustomer
                                if let navigator = self.navigationController {
                                    navigator.pushViewController(viewController, animated: true)
                                }
                            }
                        } else {
                            // User is punched out
                            
                            // Go to out status view
                            if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Status Out View Controller") as? StatusOutViewController {
                                viewController.auth = self.auth
                                viewController.user = self.user
                                viewController.timeZone = self.timeZone
                                viewController.timeZones = self.timeZones
                                if let navigator = self.navigationController {
                                    navigator.pushViewController(viewController, animated: true)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        task.resume()
    }
}
