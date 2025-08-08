//
//  Farmer.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/8/25.
//

import Foundation
import SwiftData

@Model
final class Farmer {
    var id: UUID
    var userID: UUID // Links to User model
    var farmName: String
    var farmDescription: String
    var location: String
    var latitude: Double?
    var longitude: Double?
    var certifications: [String]
    var establishedYear: Int?
    var farmSize: Double? // in hectares
    var farmingMethods: [FarmingMethod]
    var specializations: [ProductCategory]
    var contactInfo: FarmerContactInfo
    var socialMedia: FarmerSocialMedia
    var isVerified: Bool
    var rating: Double
    var totalReviews: Int
    var profileImageURL: String?
    var farmImageURLs: [String]
    var createdAt: Date
    var updatedAt: Date
    
    init(userID: UUID, farmName: String, farmDescription: String, location: String) {
        self.id = UUID()
        self.userID = userID
        self.farmName = farmName
        self.farmDescription = farmDescription
        self.location = location
        self.certifications = []
        self.farmingMethods = []
        self.specializations = []
        self.contactInfo = FarmerContactInfo()
        self.socialMedia = FarmerSocialMedia()
        self.isVerified = false
        self.rating = 0.0
        self.totalReviews = 0
        self.farmImageURLs = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct FarmerContactInfo: Codable {
    var email: String?
    var phone: String?
    var website: String?
    var address: String?
    
    init() {
        self.email = nil
        self.phone = nil
        self.website = nil
        self.address = nil
    }
}

struct FarmerSocialMedia: Codable {
    var facebook: String?
    var instagram: String?
    var twitter: String?
    
    init() {
        self.facebook = nil
        self.instagram = nil
        self.twitter = nil
    }
}
