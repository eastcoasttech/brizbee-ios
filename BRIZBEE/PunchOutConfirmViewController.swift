//
//  PunchOutConfirmViewController.swift
//  BRIZBEE
//
//  Created by Joshua Shane Martin on 8/20/19.
//  Copyright © 2019 East Coast Technology Services, LLC. All rights reserved.
//

import UIKit

class PunchOutConfirmViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    var auth: Auth?
    var user: User?
    var timeZones: [String]?
    var timeZone: String?
    
    @IBOutlet weak var timeZoneText: UITextField!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.hidesBackButton = true // Hides back button
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timeZoneText.text = timeZone
        
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

        timeZoneText.inputView = picker
        timeZoneText.inputAccessoryView = toolBar
        
        // Select the time zone
        for (index, element) in (self.timeZones?.enumerated())! {
            if (element == self.timeZone) {
                picker.selectRow(index, inComponent: 0, animated: true)
            }
        }
    }
    
    @objc func donePicker() {
        timeZoneText.resignFirstResponder()
    }
    
    @IBAction func onContinueButton(_ sender: Any) {
        self.toggleEnabled(enabled: false)
        
        // Prepare json data
        let json: [String: Any] = ["SourceForOutAt": "Mobile",
                                   "OutAtTimeZone": timeZoneText.text!]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // Create the request
        let url = URL(string: "https://brizbee.gowitheast.com/odata/Punches/Default.PunchOut")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add json data to the body
        request.httpBody = jsonData
        
        // Set the headers
        request.addValue(auth?.token ?? "", forHTTPHeaderField: "AUTH_TOKEN")
        request.addValue(auth?.userId ?? "", forHTTPHeaderField: "AUTH_USER_ID")
        request.addValue(auth?.expiration ?? "", forHTTPHeaderField: "AUTH_EXPIRATION")
        
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
        timeZoneText.text = timeZones![row]
    }
    
//    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
//        self.timeZonePicker.isHidden = false
//        return false
//    }
    
    func toggleEnabled(enabled: Bool) {
        self.loadingIndicator.isHidden = enabled
        
        self.timeZoneText.isEnabled = enabled
    }
}
