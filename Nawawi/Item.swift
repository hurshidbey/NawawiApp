//
//  Item.swift
//  Nawawi
//
//  Created by Khurshid Marazikov on 8/31/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
