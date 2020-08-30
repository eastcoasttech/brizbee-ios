//
//  StatusInViewController.swift
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

class StatusInViewController: UIViewController {
    var auth: Auth?
    var user: User?
    var timeZones: [String]?
    var timeZone: String?
    var currentTask: String?
    var currentJob: String?
    var currentCustomer: String?
    var currentSince: String?
    var currentSinceTimeZone: String?
    
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
        self.sinceLabel.text = currentSince
        self.sinceTimeZoneLabel.text = currentSinceTimeZone
        self.taskLabel.text = currentTask
        self.jobLabel.text = currentJob
        self.customerLabel.text = currentCustomer
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
}
