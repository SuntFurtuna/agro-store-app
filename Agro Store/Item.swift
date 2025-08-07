//
//  Item.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
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
