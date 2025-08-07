//
//  DemandRequest.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import Foundation
import SwiftData

@Model
final class DemandRequest {
    var id: UUID
    var requesterID: UUID
    var title: String
    var requestDescription: String
    var category: ProductCategory
    var quantity: Double
    var unit: String
    var maxPrice: Double
    var location: String
    var latitude: Double?
    var longitude: Double?
    var requiredBy: Date
    var isUrgent: Bool
    var isOrganic: Bool
    var qualityRequirements: String?
    var deliveryPreference: DeliveryOption
    var status: RequestStatus
    var createdAt: Date
    var updatedAt: Date
    var responses: [RequestResponse]
    var tags: [String]
    
    init(requesterID: UUID, title: String, description: String, category: ProductCategory, quantity: Double, unit: String, maxPrice: Double, location: String, requiredBy: Date) {
        self.id = UUID()
        self.requesterID = requesterID
        self.title = title
        self.requestDescription = description
        self.category = category
        self.quantity = quantity
        self.unit = unit
        self.maxPrice = maxPrice
        self.location = location
        self.requiredBy = requiredBy
        self.isUrgent = false
        self.isOrganic = false
        self.deliveryPreference = .pickup
        self.status = .open
        self.createdAt = Date()
        self.updatedAt = Date()
        self.responses = []
        self.tags = []
    }
}

@Model
final class RequestResponse {
    var id: UUID
    var requestID: UUID
    var farmerID: UUID
    var farmerName: String
    var offeredPrice: Double
    var availableQuantity: Double
    var message: String?
    var createdAt: Date
    var isAccepted: Bool?
    var productSamples: [String] // Image URLs
    
    init(requestID: UUID, farmerID: UUID, farmerName: String, offeredPrice: Double, availableQuantity: Double) {
        self.id = UUID()
        self.requestID = requestID
        self.farmerID = farmerID
        self.farmerName = farmerName
        self.offeredPrice = offeredPrice
        self.availableQuantity = availableQuantity
        self.createdAt = Date()
        self.productSamples = []
    }
}

enum RequestStatus: String, CaseIterable, Codable {
    case open = "open"
    case inProgress = "inProgress"
    case fulfilled = "fulfilled"
    case expired = "expired"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .open: return "Open"
        case .inProgress: return "In Progress"
        case .fulfilled: return "Fulfilled"
        case .expired: return "Expired"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: String {
        switch self {
        case .open: return "blue"
        case .inProgress: return "orange"
        case .fulfilled: return "green"
        case .expired: return "gray"
        case .cancelled: return "red"
        }
    }
}
