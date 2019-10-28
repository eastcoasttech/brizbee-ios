//
//  StatusViewController.swift
//  BRIZBEE
//
//  Created by Joshua Shane Martin on 8/20/19.
//  Copyright © 2019 East Coast Technology Services, LLC. All rights reserved.
//

import UIKit

class StatusViewController: UIViewController {
    var auth: Auth?
    var user: User?
    var timeZones: [String]?
    var timeZone: String?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var taskLabel: UILabel!
    @IBOutlet weak var taskHeaderLabel: UILabel!
    @IBOutlet weak var jobLabel: UILabel!
    @IBOutlet weak var jobHeaderLabel: UILabel!
    @IBOutlet weak var customerLabel: UILabel!
    @IBOutlet weak var customerHeaderLabel: UILabel!
    @IBOutlet weak var sinceLabel: UILabel!
    @IBOutlet weak var sinceHeaderLabel: UILabel!
    @IBOutlet weak var sinceTimeZoneLabel: UILabel!
    @IBOutlet weak var punchedInOrOutLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var punchInButton: UIButton!
    @IBOutlet weak var punchOutButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    @IBAction func onPunchInButton(_ sender: Any) {
        performSegue(withIdentifier: "punchInSegue", sender: self)
    }
    
    @IBAction func onPunchOutButton(_ sender: Any) {
        performSegue(withIdentifier: "punchOutSegue", sender: self)
    }
    
    @IBAction func onLogoutButton(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.hidesBackButton = true // Hides back button
        
        // Update the labels
        let nameString = String(format: "Hello, %@", (user?.name ?? ""))
        nameLabel.text = nameString
        
        self.loadCurrentPunch()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "punchInSegue" {
            let controller = segue.destination as! PunchInTaskIdViewController
            controller.auth = self.auth
            controller.timeZone = self.timeZone
            controller.timeZones = self.timeZones
            controller.user = self.user
        } else if segue.identifier == "punchOutSegue" {
            let controller = segue.destination as! PunchOutConfirmViewController
            controller.auth = self.auth
            controller.timeZone = self.timeZone
            controller.timeZones = self.timeZones
            controller.user = self.user
        }
    }
    
    func loadCurrentPunch() {
        self.toggleLoading(loading: true) // Hide everything
        
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
                            self.punchedInOrOutLabel.text = "You are PUNCHED IN"
                            self.punchedInOrOutLabel.textColor = UIColor(red: 102/255, green: 180/255, blue: 49/255, alpha: 1.0)
                            
                            // Since
                            let inAt = valueFirstJSON?["InAt"] as? String ?? ""
                            
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                            dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
                            let date = dateFormatter.date(from:inAt)!
                            
                            let humanFormatter = DateFormatter()
                            humanFormatter.dateFormat = "MMM dd, yyyy h:mm a"
                            let humanString = humanFormatter.string(from: date)
                            self.sinceLabel.text = humanString
                            
                            // Since Time Zone
                            let inAtTimeZone = valueFirstJSON?["InAtTimeZone"] as? String ?? ""
                            self.sinceTimeZoneLabel.text = inAtTimeZone
                            
                            // Use this time zone to punch in or out later
                            self.timeZone = inAtTimeZone
                            
                            // Task
                            let task = valueFirstJSON?["Task"] as? [String: Any]
                            let taskNumber = task?["Number"] as? String ?? ""
                            let taskName = task?["Name"] as? String ?? ""
                            let taskString = String(format: "%@ - %@", taskNumber, taskName)
                            self.taskLabel.text = taskString
                            
                            // Job
                            let job = task?["Job"] as? [String: Any]
                            let jobNumber = job?["Number"] as? String ?? ""
                            let jobName = job?["Name"] as? String ?? ""
                            let jobString = String(format: "%@ - %@", jobNumber, jobName)
                            self.jobLabel.text = jobString
                            
                            // Customer
                            let customer = job?["Customer"] as? [String: Any]
                            let customerNumber = customer?["Number"] as? String ?? ""
                            let customerName = customer?["Name"] as? String ?? ""
                            let customerString = String(format: "%@ - %@", customerNumber, customerName)
                            self.customerLabel.text = customerString
                            
                            self.toggleLoading(loading: false) // Show everything
                            
                            self.punchOutButton.isEnabled = true
                        } else {
                            // User is punched out
                            self.punchedInOrOutLabel.text = "You are PUNCHED OUT"
                            self.punchedInOrOutLabel.textColor = UIColor(red: 204/255, green: 0/255, blue: 0/255, alpha: 1.0)
                            
                            // Use this time zone to punch in later
                            self.timeZone = self.user?.timeZone
                            
                            self.toggleLoading(loading: false) // Show everything
                            
                            self.taskLabel.isHidden = true
                            self.taskHeaderLabel.isHidden = true
                            self.jobLabel.isHidden = true
                            self.jobHeaderLabel.isHidden = true
                            self.customerLabel.isHidden = true
                            self.customerHeaderLabel.isHidden = true
                            self.sinceLabel.isHidden = true
                            self.sinceHeaderLabel.isHidden = true
                            self.sinceTimeZoneLabel.isHidden = true
                            self.punchOutButton.isEnabled = false
                        }
                    }
                }
            }
        }
        
        task.resume()
    }
    
    func toggleLoading(loading: Bool) {
        self.loadingIndicator.isHidden = !loading
        
        self.nameLabel.isHidden = loading
        self.taskLabel.isHidden = loading
        self.taskHeaderLabel.isHidden = loading
        self.jobLabel.isHidden = loading
        self.jobHeaderLabel.isHidden = loading
        self.customerLabel.isHidden = loading
        self.customerHeaderLabel.isHidden = loading
        self.sinceLabel.isHidden = loading
        self.sinceHeaderLabel.isHidden = loading
        self.sinceTimeZoneLabel.isHidden = loading
        self.punchedInOrOutLabel.isHidden = loading
        self.punchInButton.isHidden = loading
        self.punchOutButton.isHidden = loading
        self.logoutButton.isHidden = loading
    }
}
