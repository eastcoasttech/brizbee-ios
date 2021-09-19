//
//  QBDInventoryItem.swift
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
//  Created by Joshua Shane Martin on 7/11/21.
//

import Foundation

struct QBDInventoryItem {
    let id: Int64
    let fullName: String
    let barCodeValue: String
    let listId: String
    let name: String
    let manufacturerPartNumber: String
    let purchaseCost: String
    let purchaseDescription: String
    let salesPrice: String
    let salesDescription: String
}
