//
//  PunchInConfirmViewController.swift
//  BRIZBEE
//
//  Created by Joshua Shane Martin on 8/20/19.
//  Copyright © 2019 East Coast Technology Services, LLC. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class PunchInConfirmViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, CLLocationManagerDelegate {
    var auth: Auth?
    var user: User?
    var task: [String: Any]?
    var timeZone: String?
    var timeZones: [String]?
    var taskNumber: [String]?
    var latitude = ""
    var longitude = ""
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var taskLabel: UILabel!
    @IBOutlet weak var taskHeaderLabel: UILabel!
    @IBOutlet weak var jobLabel: UILabel!
    @IBOutlet weak var jobHeaderLabel: UILabel!
    @IBOutlet weak var customerLabel: UILabel!
    @IBOutlet weak var customerHeaderLabel: UILabel!
    @IBOutlet weak var timeZoneTextField: UITextField!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.hidesBackButton = true // Hides back button
        
        // Task
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timeZoneTextField.text = timeZone
        
        let picker: UIPickerView
        picker = UIPickerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 300))
        picker.backgroundColor = .white

        picker.showsSelectionIndicator = true
        picker.delegate = self
        picker.dataSource = self

        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
        toolBar.sizeToFit()

        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(self.donePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.donePicker))

        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true

        timeZoneTextField.inputView = picker
        timeZoneTextField.inputAccessoryView = toolBar
        
        // Select the time zone
        for (index, element) in (self.timeZones?.enumerated())! {
            if (element == self.timeZone) {
                picker.selectRow(index, inComponent: 0, animated: true)
            }
        }
        
        // Location only needed while app is open
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    @IBAction func onContinueButton(_ sender: Any) {
        self.toggleEnabled(enabled: false)
        
        // Prepare json data
        let json: [String: Any] = ["TaskId" : self.task!["Id"]!,
                                   "SourceForInAt": "Mobile",
                                   "InAtTimeZone": timeZoneTextField.text!,
                                   "LatitudeForInAt": latitude,
                                   "LongitudeForInAt": longitude]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // Create the request
        let url = URL(string: "https://brizbee.gowitheast.com/odata/Punches/Default.PunchIn")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add json data to the body
        request.httpBody = jsonData
        
        // Set the headers
        request.addValue(self.auth?.token ?? "", forHTTPHeaderField: "AUTH_TOKEN")
        request.addValue(self.auth?.userId ?? "", forHTTPHeaderField: "AUTH_USER_ID")
        request.addValue(self.auth?.expiration ?? "", forHTTPHeaderField: "AUTH_EXPIRATION")
        
        // Send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                self.toggleEnabled(enabled: true)
                return
            }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if (responseJSON as? [String: Any]) != nil {
                DispatchQueue.main.async {
                    // Return to Status View Controller
                    if let navigator = self.navigationController {
                        navigator.popToViewController(navigator.viewControllers[1], animated: true)
                    }
                }
            }
        }
        
        task.resume()
    }
    
    // Return to Status View Controller
    @IBAction func onCancelButton(_ sender: Any) {
        if let navigator = self.navigationController {
            navigator.popToViewController(navigator.viewControllers[1], animated: true)
        }
    }
    
    @objc func donePicker() {
        timeZoneTextField.resignFirstResponder()
    }
    
    // Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return timeZones!.count
    }

    // The data to return fopr the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return timeZones![row]
    }
    
    // Set text to selected time zone
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        timeZoneTextField.text = timeZones![row]
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        latitude = String(locValue.latitude)
        longitude = String(locValue.longitude)
    }
    
    func toggleEnabled(enabled: Bool) {
        self.loadingIndicator.isHidden = enabled
        
        self.continueButton.isEnabled = enabled
        self.cancelButton.isEnabled = enabled
        self.taskLabel.isEnabled = enabled
        self.jobLabel.isHidden = enabled
        self.customerLabel.isHidden = enabled
    }
}
