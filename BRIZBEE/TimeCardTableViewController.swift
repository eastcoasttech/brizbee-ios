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
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var hourStepper: UIStepper!
    @IBOutlet weak var minuteStepper: UIStepper!
    @IBOutlet weak var hourLabel: UILabel!
    @IBOutlet weak var minuteLabel: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the back button
        navigationItem.hidesBackButton = true
    }
    
    @IBAction func onCancelButton(_ sender: Any) {
        if let navigator = self.navigationController {
            // Return to Status View Controller
            navigator.popToViewController(navigator.viewControllers[1], animated: true)
        }
    }
    
    @IBAction func onHourChanged(_ sender: Any) {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        
        hourLabel.text = formatter.string(from: hourStepper.value as NSNumber) ?? "0"
    }
    
    @IBAction func onMinuteChanged(_ sender: Any) {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        
        minuteLabel.text = formatter.string(from: minuteStepper.value as NSNumber) ?? "0"
    }
    
//    @IBAction func datePickerChanged(_ sender: Any) {
//        let dateFormatter = DateFormatter()
//
//        dateFormatter.dateStyle = DateFormatter.Style.short
//        dateFormatter.timeStyle = DateFormatter.Style.short
//
//        let strDate = dateFormatter.string(from: datePicker.date)
//        dateLabel.text = strDate
//    }
}
