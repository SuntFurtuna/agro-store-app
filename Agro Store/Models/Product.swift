//
//  Product.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import Foundation
import SwiftData

@Model
final class Product {
    var id: UUID
    var name: String
    var productDescription: String
    var category: ProductCategory
    var price: Double
    var unit: String // kg, pieces, liters, etc.
    var minimumOrder: Double
    var availableQuantity: Double
    var imageURLs: [String]
    var farmerID: UUID
    var farmerName: String? // Cache farmer name for quick display
    var isOrganic: Bool
    var harvestDate: Date?
    var expiryDate: Date?
    var location: String
    var latitude: Double?
    var longitude: Double?
    var isAvailable: Bool
    var farmingMethod: FarmingMethod?
    var deliveryOptions: [DeliveryOption]
    var createdAt: Date
    var updatedAt: Date
    var views: Int
    var likes: Int
    var tags: [String]
    
    init(name: String, description: String, category: ProductCategory, price: Double, unit: String, farmerID: UUID, farmerName: String, location: String) {
        self.id = UUID()
        self.name = name
        self.productDescription = description
        self.category = category
        self.price = price
        self.unit = unit
        self.minimumOrder = 1.0
        self.availableQuantity = 0.0
        self.imageURLs = []
        self.farmerID = farmerID
        self.farmerName = farmerName
        self.isOrganic = false
        self.location = location
        self.isAvailable = true
        self.deliveryOptions = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.views = 0
        self.likes = 0
        self.tags = []
    }
}

enum FarmingMethod: String, CaseIterable, Codable {
    case organic = "organic"
    case conventional = "conventional"
    case biodynamic = "biodynamic"
    case permaculture = "permaculture"
    case hydroponic = "hydroponic"
    case greenhouse = "greenhouse"
    
    var displayName: String {
        switch self {
        case .organic: return "Organic"
        case .conventional: return "Conventional"
        case .biodynamic: return "Biodynamic"
        case .permaculture: return "Permaculture"
        case .hydroponic: return "Hydroponic"
        case .greenhouse: return "Greenhouse"
        }
    }
    
    var icon: String {
        switch self {
        case .organic: return "leaf.fill"
        case .conventional: return "circle.fill"
        case .biodynamic: return "moon.fill"
        case .permaculture: return "tree.fill"
        case .hydroponic: return "drop.fill"
        case .greenhouse: return "building.2.fill"
        }
    }
}

enum ProductCategory: String, CaseIterable, Codable {
    case vegetables = "vegetables"
    case fruits = "fruits"
    case grains = "grains"
    case dairy = "dairy"
    case meat = "meat"
    case herbs = "herbs"
    case wine = "wine"
    case honey = "honey"
    case eggs = "eggs"
    case nuts = "nuts"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .vegetables: return "Vegetables"
        case .fruits: return "Fruits"
        case .grains: return "Grains & Cereals"
        case .dairy: return "Dairy Products"
        case .meat: return "Meat & Poultry"
        case .herbs: return "Herbs & Spices"
        case .wine: return "Wine & Beverages"
        case .honey: return "Honey & Bee Products"
        case .eggs: return "Eggs"
        case .nuts: return "Nuts & Seeds"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .vegetables: return "carrot.fill"
        case .fruits: return "apple.logo"
        case .grains: return "leaf.arrow.circlepath"
        case .dairy: return "drop.fill"
        case .meat: return "triangle.fill"
        case .herbs: return "leaf.fill"
        case .wine: return "wineglass.fill"
        case .honey: return "hexagon.fill"
        case .eggs: return "oval.fill"
        case .nuts: return "circle.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}

enum DeliveryOption: String, CaseIterable, Codable {
    case pickup = "pickup"
    case delivery = "delivery"
    case shipping = "shipping"
    
    var displayName: String {
        switch self {
        case .pickup: return "Farm Pickup"
        case .delivery: return "Local Delivery"
        case .shipping: return "Shipping"
        }
    }
    
    var icon: String {
        switch self {
        case .pickup: return "location.fill"
        case .delivery: return "car.fill"
        case .shipping: return "box.fill"
        }
    }
}
