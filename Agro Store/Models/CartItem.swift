//
//  CartItem.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/8/25.
//

import Foundation
import SwiftData

@Model
final class CartItem {
    var id: UUID
    var userID: UUID
    var productID: UUID
    var productName: String
    var productPrice: Double
    var quantity: Double
    var unit: String
    var deliveryOption: DeliveryOption
    var createdAt: Date
    
    init(userID: UUID, productID: UUID, productName: String, productPrice: Double, quantity: Double, unit: String, deliveryOption: DeliveryOption) {
        self.id = UUID()
        self.userID = userID
        self.productID = productID
        self.productName = productName
        self.productPrice = productPrice
        self.quantity = quantity
        self.unit = unit
        self.deliveryOption = deliveryOption
        self.createdAt = Date()
    }
    
    var totalPrice: Double {
        return quantity * productPrice
    }
}
