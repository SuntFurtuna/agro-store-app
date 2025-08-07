//
//  Order.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import Foundation
import SwiftData

@Model
final class Order {
    var id: UUID
    var customerID: UUID
    var farmerID: UUID
    var items: [OrderItem]
    var totalAmount: Double
    var status: OrderStatus
    var deliveryOption: DeliveryOption
    var deliveryAddress: String?
    var deliveryDate: Date?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var paymentStatus: PaymentStatus
    var customerRating: Double?
    var customerReview: String?
    var farmerRating: Double?
    var farmerReview: String?
    
    init(customerID: UUID, farmerID: UUID, items: [OrderItem], totalAmount: Double, deliveryOption: DeliveryOption) {
        self.id = UUID()
        self.customerID = customerID
        self.farmerID = farmerID
        self.items = items
        self.totalAmount = totalAmount
        self.status = .pending
        self.deliveryOption = deliveryOption
        self.createdAt = Date()
        self.updatedAt = Date()
        self.paymentStatus = .pending
    }
}

@Model
final class OrderItem {
    var id: UUID
    var productID: UUID
    var productName: String
    var quantity: Double
    var unitPrice: Double
    var totalPrice: Double
    
    init(productID: UUID, productName: String, quantity: Double, unitPrice: Double) {
        self.id = UUID()
        self.productID = productID
        self.productName = productName
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.totalPrice = quantity * unitPrice
    }
}

enum OrderStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case confirmed = "confirmed"
    case preparing = "preparing"
    case ready = "ready"
    case delivered = "delivered"
    case cancelled = "cancelled"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .preparing: return "Preparing"
        case .ready: return "Ready for Pickup/Delivery"
        case .delivered: return "Delivered"
        case .cancelled: return "Cancelled"
        case .completed: return "Completed"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .confirmed: return "blue"
        case .preparing: return "yellow"
        case .ready: return "purple"
        case .delivered: return "green"
        case .cancelled: return "red"
        case .completed: return "green"
        }
    }
}

enum PaymentStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case paid = "paid"
    case failed = "failed"
    case refunded = "refunded"
    
    var displayName: String {
        switch self {
        case .pending: return "Payment Pending"
        case .paid: return "Paid"
        case .failed: return "Payment Failed"
        case .refunded: return "Refunded"
        }
    }
}
