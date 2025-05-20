//
//  Item.swift
//  ClutterBug
//
//  Created by David Watson on 5/20/25.
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
