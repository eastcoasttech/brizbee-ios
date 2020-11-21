//
//  InputViewTableViewCell.swift
//  BRIZBEE
//
//  Created by Joshua Shane Martin on 11/21/20.
//  Copyright © 2020 East Coast Technology Services, LLC. All rights reserved.
//

import UIKit

class InputViewTableViewCell: UITableViewCell {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapInputViewLabel))
        tapRecognizer.numberOfTapsRequired = 1
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(tapRecognizer)
    }
    
    @objc private func tapInputViewLabel() {
        let label: InputViewLabel = self.contentView.viewWithTag(1) as! InputViewLabel
        label.becomeFirstResponder()
    }
}
