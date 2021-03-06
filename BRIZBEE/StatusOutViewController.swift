//
//  StatusOutViewController.swift
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

class StatusOutViewController: UIViewController {
    var auth: Auth?
    var user: User?
    var timeZones: [String]?
    var timeZone: String?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var punchInButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var timeCardButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBAction func onPunchInButton(_ sender: UIButton) {
        // Reduce the button opacity.
        sender.alpha = 0.5

        // Return button opacity after delay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            sender.alpha = 1.0
        }
        
        performSegue(withIdentifier: "punchInSegue", sender: self)
    }
    
    @IBAction func onLogoutButton(_ sender: UIButton) {
        // Reduce the button opacity.
        sender.alpha = 0.5

        // Return button opacity after delay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            sender.alpha = 1.0
        }
        
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.hidesBackButton = true // Hides back button
        
        // Update the labels.
        let nameString = String(format: "Hello, %@", (user?.name ?? ""))
        nameLabel.text = nameString
        
        // Check if user is allowed to use time cards.
        if (user?.usesTimeCards == false) {
            self.timeCardButton.removeFromSuperview()
        }
        
        // Scroll to top.
        scrollView.setContentOffset(.zero, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "punchInSegue" {
            let controller = segue.destination as! PunchInTaskIdViewController
            controller.auth = self.auth
            controller.timeZone = self.timeZone
            controller.timeZones = self.timeZones
            controller.user = self.user
        } else if segue.identifier == "timeCardSegue" {
            let controller = segue.destination as! TimeCardTableViewController
            controller.auth = self.auth
            controller.user = self.user
        } else if segue.identifier == "inventoryItemSegue" {
            let controller = segue.destination as! InventoryItemViewController
            controller.auth = self.auth
            controller.user = self.user
        }
    }
}
