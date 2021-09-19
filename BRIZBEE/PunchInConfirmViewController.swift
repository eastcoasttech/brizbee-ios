//
//  PunchInConfirmViewController.swift
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

import UIKit
import CoreLocation

class PunchInConfirmViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, CLLocationManagerDelegate {
    var auth: Auth?
    var user: User?
    var task: [String: Any]?
    var timeZones: [String]?
    var timeZone: String?
    var taskNumber: [String]?
    var latitude = ""
    var longitude = ""
    let locationManager = CLLocationManager()
    var loadingVC: LoadingViewController?
    
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
        
        // Hide the back button.
        navigationItem.hidesBackButton = true
        
        // Set the task
        let taskNumber = task?["Number"] as? String ?? ""
        let taskName = task?["Name"] as? String ?? ""
        let taskString = String(format: "%@ - %@", taskNumber, taskName)
        self.taskLabel.text = taskString
        
        // Set the job
        let job = task?["Job"] as? [String: Any]
        let jobNumber = job?["Number"] as? String ?? ""
        let jobName = job?["Name"] as? String ?? ""
        let jobString = String(format: "%@ - %@", jobNumber, jobName)
        self.jobLabel.text = jobString
        
        // Set the customer
        let customer = job?["Customer"] as? [String: Any]
        let customerNumber = customer?["Number"] as? String ?? ""
        let customerName = customer?["Name"] as? String ?? ""
        let customerString = String(format: "%@ - %@", customerNumber, customerName)
        self.customerLabel.text = customerString
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Time Zone may not be populated if user is not punched in
        if timeZone?.isEmpty ?? true {
            timeZoneTextField.text = user?.timeZone
        } else {
            timeZoneTextField.text = timeZone
        }
        
        // Set padding
        let paddingView1: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: self.timeZoneTextField.frame.height))
        timeZoneTextField.leftView = paddingView1
        timeZoneTextField.leftViewMode = .always
        
        let picker: UIPickerView
        picker = UIPickerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 300))
        if #available(iOS 13.0, *) {
            picker.backgroundColor = .secondarySystemBackground
        } else {
            // Dark mode is not applicable
            picker.backgroundColor = .white
        }

        picker.showsSelectionIndicator = true
        picker.delegate = self
        picker.dataSource = self

        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        if #available(iOS 13.0, *) {
            toolBar.tintColor = .label
        } else {
            // Dark mode is not applicable
            toolBar.tintColor = .black
        }
        toolBar.isTranslucent = true
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
        
        // Build the URL.
        var components = URLComponents()
        components.scheme = Constants.scheme
        components.host = Constants.host
        components.path = "/api/Kiosk/PunchIn"

        components.queryItems = [
            URLQueryItem(name: "taskId", value: String(self.task?["Id"] as! Int64)),
            URLQueryItem(name: "timeZone", value: timeZoneTextField.text!),
            URLQueryItem(name: "latitude", value: latitude),
            URLQueryItem(name: "longitude", value: longitude),
            URLQueryItem(name: "sourceHardware", value: "Mobile"),
            URLQueryItem(name: "sourceOperatingSystem", value: "iOS"),
            URLQueryItem(name: "sourceOperatingSystemVersion", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String),
            URLQueryItem(name: "sourceBrowser", value: "N/A"),
            URLQueryItem(name: "sourceBrowserVersion", value: "N/A")
        ]
        
        // Build the request.
        let url = URL(string: components.string!)!
        
        print(url)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Set the headers.
        request.addValue(self.auth?.token ?? "", forHTTPHeaderField: "AUTH_TOKEN")
        request.addValue(self.auth?.userId ?? "", forHTTPHeaderField: "AUTH_USER_ID")
        request.addValue(self.auth?.expiration ?? "", forHTTPHeaderField: "AUTH_EXPIRATION")
        
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
            if (responseJSON as? [String: Any]) != nil {
                
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

    // The data to return for the row and component (column) that's being passed in
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
