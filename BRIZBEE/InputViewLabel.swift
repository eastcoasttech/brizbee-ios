//
//  InputViewLabel.swift
//  BRIZBEE Mobile for iOS
//
//  Copyright © 2020 East Coast Technology Services, LLC
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
//  Created by Joshua Shane Martin on 11/18/20.
//

import UIKit

class InputViewLabel: UILabel, UIPickerViewDelegate, UIPickerViewDataSource {
    private var _inputView: UIView? {
        get {
            let picker = UIPickerView(frame: CGRect(x: 0, y: 0, width: (self.superview?.frame.width)!, height: 300))
            picker.backgroundColor = .white
            picker.showsSelectionIndicator = true
            picker.isUserInteractionEnabled = true
            picker.delegate = self
            picker.dataSource = self
            
            // Will allow for selecting the row before becoming first responder
            picker.selectRow(self.rowForObject(object: self.selected as Any), inComponent: 0, animated: true)
            
            return picker
        }
    }

    private var _inputAccessoryToolbar: UIToolbar = {
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.tintColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
        toolBar.isTranslucent = true
        toolBar.isUserInteractionEnabled = true

        toolBar.sizeToFit()

        return toolBar
    }()

    override var inputView: UIView? {
        return _inputView
    }

    override var inputAccessoryView: UIView? {
        return _inputAccessoryToolbar
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(doneClick))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(doneClick))

        _inputAccessoryToolbar.setItems([cancelButton, spaceButton, doneButton], animated: false)

//        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(launchPicker))
//        tapRecognizer.numberOfTapsRequired = 1
//        self.isUserInteractionEnabled = true
//        self.addGestureRecognizer(tapRecognizer)
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    var selectedItemChangedHandler: (Any) -> Void = { _ in }

//    @objc private func launchPicker() {
//        becomeFirstResponder()
//    }

    @objc private func doneClick() {
        resignFirstResponder()
    }
    
    func setItems(items: [Any], selected: Any?) {
        self.items = items
        
        // Select the first item or the given item
        if (selected == nil) {
            self.selected = self.items[0]
        } else {
            self.selected = selected
        }
        
        DispatchQueue.main.async {
            self.selectedItemChanged()
        }
    }
    
    private func selectedItemChanged() {
        if self.selected is Customer {
            text = (self.selected as? Customer)?.nameWithNumber
        } else if self.selected is Job {
            text = (self.selected as? Job)?.nameWithNumber
        } else if self.selected is Task {
            text = (self.selected as? Task)?.nameWithNumber
        } else if self.selected is NSNumber {
            text = (self.selected as! NSNumber).stringValue
        } else {
            text = ""
        }
        
        // Fire the selected item changed handler
        selectedItemChangedHandler(self.selected as Any)
    }
    
    private func rowForObject(object: Any) -> Int {
        // Determine the type of the object and find its index
        if object is Customer {
            if let index = self.items.firstIndex(where: { ($0 as! Customer).id == (object as! Customer).id }) {
                return index
            } else {
                return 0
            }
        }
        else if object is Job {
            if let index = self.items.firstIndex(where: { ($0 as! Job).id == (object as! Job).id }) {
                return index
            } else {
                return 0
            }
        } else if object is Task {
            if let index = self.items.firstIndex(where: { ($0 as! Task).id == (object as! Task).id }) {
                return index
            } else {
                return 0
            }
        } else if object is NSNumber {
            if let index = self.items.firstIndex(where: { $0 as! NSNumber == object as! NSNumber }) {
                return index
            } else {
                return 0
            }
        } else {
            return 0
        }
    }
    
    // -----------------------------------------------------------
    // Picker Delegate
    // -----------------------------------------------------------
    
    var selected: Any?
    var items: [Any] = []
    var label: InputViewLabel?
    
    // Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return items.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if items[row] is Customer {
            return (items[row] as? Customer)?.nameWithNumber
        } else if items[row] is Job {
            return (items[row] as? Job)?.nameWithNumber
        } else if items[row] is Task {
            return (items[row] as? Task)?.nameWithNumber
        } else if items[row] is NSNumber {
            return (items[row] as! NSNumber).stringValue
        } else {
            return ""
        }
    }
    
    // Set label text to selected item
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selected = items[row]
        self.selectedItemChanged()
    }
}
