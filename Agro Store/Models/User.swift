//
//  User.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import Foundation
import SwiftData

@Model
final class User {
    var id: UUID
    var name: String
    var email: String
    var phone: String
    var userType: UserType
    var location: String
    var latitude: Double?
    var longitude: Double?
    var profileImageURL: String?
    var isProSubscriber: Bool
    var subscriptionExpiryDate: Date?
    var createdAt: Date
    var isVerified: Bool
    var rating: Double
    var totalReviews: Int
    
    // Farm-specific details
    var farmName: String?
    var farmDescription: String?
    var certifications: [String]
    var establishedYear: Int?
    
    init(name: String, email: String, phone: String, userType: UserType, location: String) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.phone = phone
        self.userType = userType
        self.location = location
        self.isProSubscriber = false
        self.createdAt = Date()
        self.isVerified = false
        self.rating = 0.0
        self.totalReviews = 0
        self.certifications = []
    }
}

enum UserType: String, CaseIterable, Codable {
    case farmer = "farmer"
    case consumer = "consumer"
    case retailer = "retailer"
    case restaurant = "restaurant"
    
    var displayName: String {
        switch self {
        case .farmer: return "Farmer/Producer"
        case .consumer: return "Consumer"
        case .retailer: return "Retailer"
        case .restaurant: return "Restaurant"
        }
    }
    
    var icon: String {
        switch self {
        case .farmer: return "leaf.fill"
        case .consumer: return "person.fill"
        case .retailer: return "storefront.fill"
        case .restaurant: return "fork.knife"
        }
    }
}
