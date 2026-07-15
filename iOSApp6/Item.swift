//
//  Item.swift
//  iOSApp6
//
//  Created by Etefworkie Melaku on 2026-07-15.
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
