//
//  PunchOutConfirmViewController.swift
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

class PunchOutConfirmViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, CLLocationManagerDelegate {
    var auth: Auth?
    var user: User?
    var timeZones: [String]?
    var timeZone: String?
    var latitude = ""
    var longitude = ""
    let locationManager = CLLocationManager()
    var loadingVC: LoadingViewController?
    
    @IBOutlet weak var timeZoneTextField: UITextField!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the back button.
        navigationItem.hidesBackButton = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Time Zone will be populated because user is punched in
        timeZoneTextField.text = timeZone
        
        // Set padding
        let paddingView1: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: self.timeZoneTextField.frame.height))
        timeZoneTextField.leftView = paddingView1
        timeZoneTextField.leftViewMode = .always
        
        let picker: UIPickerView
        picker = UIPickerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 300))
        picker.backgroundColor = .secondarySystemBackground
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
    
    @objc func donePicker() {
        timeZoneTextField.resignFirstResponder()
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
        components.path = "/api/Kiosk/PunchOut"

        components.queryItems = [
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
            navigator.popViewController(animated: true)
        }
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
