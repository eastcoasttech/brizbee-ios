//
//  TimeCardTableViewController.swift
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

class TimeCardTableViewController: UITableViewController {
    var auth: Auth?
    var user: User?
    var customers: [Customer] = []
    var jobs: [Job] = []
    var tasks: [Task] = []
    var customer: Customer?
    var job: Job?
    var task: Task?
    var customerPicker: UIPickerView?
    var jobPicker: UIPickerView?
    var taskPicker: UIPickerView?
    var hour: NSNumber = 0
    var minute: NSNumber = 0
    var loadingVC: LoadingViewController?
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var customerLabel: InputViewLabel!
    @IBOutlet weak var jobLabel: InputViewLabel!
    @IBOutlet weak var taskLabel: InputViewLabel!
    @IBOutlet weak var hourLabel: InputViewLabel!
    @IBOutlet weak var minuteLabel: InputViewLabel!
    @IBOutlet weak var notesTextView: UITextView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the back button.
        navigationItem.hidesBackButton = true
    }
    
    @IBAction func onContinueButton(_ sender: UIButton) {
        // Reduce the button opacity.
        sender.alpha = 0.5

        // Return button opacity after delay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            sender.alpha = 1.0
        }
        
        // Hide toolbar.
        self.view.endEditing(true)
        
        // Show loading indicator.
        self.loadingVC = LoadingViewController()
        self.loadingVC!.modalPresentationStyle = .overCurrentContext
        self.loadingVC!.modalTransitionStyle = .crossDissolve
        self.present(loadingVC!, animated: true, completion: nil)
        
        if ((Int(truncating: hour) + Int(truncating: minute)) == 0) {
            let uialert = UIAlertController(title: "Oops!", message: "Must specify hours and minutes.", preferredStyle: UIAlertController.Style.alert)
            uialert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
            self.present(uialert, animated: true, completion: nil)
            return
        }
        
        // Format the entered date.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let enteredAt = dateFormatter.string(from: datePicker.date)
        
        // Build the URL.
        var components = URLComponents()
        components.scheme = Constants.scheme
        components.host = Constants.host
        components.path = "/api/Kiosk/Timecard"

        components.queryItems = [
            URLQueryItem(name: "taskId", value: String(self.task!.id)),
            URLQueryItem(name: "enteredAt", value: enteredAt),
            URLQueryItem(name: "minutes", value: String((Int(truncating: hour) * 60) + Int(truncating: minute)))
        ]
        
        // Notes are optional.
        if (!notesTextView.text!.isEmpty) {
            components.queryItems?.append(
                URLQueryItem(name: "notes", value: notesTextView.text!)
            )
        }
        
        // Build the request.
        let url = URL(string: components.string!)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
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
            
            let json = try? JSONSerialization.jsonObject(with: data!, options: [])
            if (json as? [String: Any]) != nil {
                
                DispatchQueue.main.async {
                    
                    if let navigator = self.navigationController {
                        
                        // Dismiss loading indicator and then pop.
                        self.loadingVC!.dismiss(animated: true, completion: {
                            navigator.popToViewController(navigator.viewControllers[1], animated: true)
                        })
                    }
                }
            }
        }
        
        task.resume()
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure hour and minute picker
        
        hourLabel.selectedItemChangedHandler = {
            (item: Any) -> Void in
            
            self.hour = item as! NSNumber
            // No need to do anything
        }
        
        minuteLabel.selectedItemChangedHandler = {
            (item: Any) -> Void in
            
            self.minute = item as! NSNumber
            // No need to do anything
        }
        
        // Maximum 23 hours in a day
        var h: [NSNumber] = []
        for n in 0...23 {
            h.append(NSNumber(value: n))
        }
        hourLabel.setItems(items: h, selected: self.hour)
        
        // Maximum 59 minutes in an hour
        var m: [NSNumber] = []
        for n in 0...59 {
            m.append(NSNumber(value: n))
        }
        minuteLabel.setItems(items: m, selected: self.minute)
        
        // Configure customer, job, and task picker
        
        customerLabel.selectedItemChangedHandler = {
            (item: Any) -> Void in
        
            self.customer = item as? Customer
            self.reloadJobs()
        }
        
        jobLabel.selectedItemChangedHandler = {
            (item: Any) -> Void in
            
            self.job = item as? Job
            self.reloadTasks()
        }
        
        taskLabel.selectedItemChangedHandler = {
            (item: Any) -> Void in
            
            self.task = item as? Task
            // No need to do anything
        }
        
        // Must trigger initial load
        reloadCustomers()
    }
    
    func reloadCustomers() {
        
        // Build the URL.
        var components = URLComponents()
        components.scheme = Constants.scheme
        components.host = Constants.host
        components.path = "/api/Kiosk/Customers"
        
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
            
            let json = try? JSONSerialization.jsonObject(with: data!, options: [])
            if let json = json as? [Any] {
                
                // Reset the customers, jobs, and tasks
                self.customers = []
                self.customer = nil
                self.jobs = []
                self.job = nil
                self.tasks = []
                self.task = nil
                
                for item in json {
                    if let itemJSON = item as? [String: Any] {
                        let name = itemJSON["name"] as? String
                        let id = itemJSON["id"] as? Int64
                        let number = itemJSON["number"] as? String
                        let customer = Customer(name: name!, id: id!, number: number!)
                        self.customers.append(customer)
                    }
                }
                
                // Set the items
                self.customerLabel.setItems(items: self.customers, selected: self.customer as Any?)
            }
        }
        
        task.resume()
    }
    
    func reloadJobs() {
        
        // Build the URL.
        var components = URLComponents()
        components.scheme = Constants.scheme
        components.host = Constants.host
        components.path = "/api/Kiosk/Projects"

        components.queryItems = [
            URLQueryItem(name: "customerId", value: String(customer!.id))
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
                (200...299).contains(httpResponse.statusCode) else {
                
                let responseData = String(data: data!, encoding: String.Encoding.utf8)
                
                self.handleError(error: responseData)
                
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data!, options: [])
            if let json = json as? [Any] {
                
                // Reset the jobs and tasks
                self.jobs = []
                self.job = nil
                self.tasks = []
                self.task = nil
                
                for item in json {
                    if let itemJSON = item as? [String: Any] {
                        let name = itemJSON["name"] as? String
                        let id = itemJSON["id"] as? Int64
                        let number = itemJSON["number"] as? String
                        let job = Job(name: name!, id: id!, number: number!, customerId: self.customer!.id)
                        self.jobs.append(job)
                    }
                }
                
                // Set the items
                self.jobLabel.setItems(items: self.jobs, selected: self.job as Any?)
            }
        }
        
        task.resume()
    }
    
    func reloadTasks() {
        
        // Build the URL.
        var components = URLComponents()
        components.scheme = Constants.scheme
        components.host = Constants.host
        components.path = "/api/Kiosk/Tasks"

        components.queryItems = [
            URLQueryItem(name: "projectId", value: String(job!.id))
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
                (200...299).contains(httpResponse.statusCode) else {
                
                let responseData = String(data: data!, encoding: String.Encoding.utf8)
                
                self.handleError(error: responseData)
                
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data!, options: [])
            if let json = json as? [Any] {
                
                // Reset the tasks
                self.tasks = []
                self.task = nil
                
                for item in json {
                    if let itemJSON = item as? [String: Any] {
                        let name = itemJSON["name"] as? String
                        let id = itemJSON["id"] as? Int64
                        let number = itemJSON["number"] as? String
                        let task = Task(name: name!, id: id!, number: number!, jobId: self.job!.id)
                        self.tasks.append(task)
                    }
                }
                
                // Set the items
                self.taskLabel.setItems(items: self.tasks, selected: self.task as Any?)
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
