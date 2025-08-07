//
//  Subscription.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import Foundation
import SwiftData

@Model
final class Subscription {
    var id: UUID
    var userID: UUID
    var plan: SubscriptionPlan
    var startDate: Date
    var endDate: Date
    var isActive: Bool
    var autoRenew: Bool
    var paymentMethod: String?
    var createdAt: Date
    var analyticsAccess: Bool
    var prioritySupport: Bool
    var unlimitedListings: Bool
    var featuredListings: Int
    var commissionRate: Double // Percentage
    
    init(userID: UUID, plan: SubscriptionPlan) {
        self.id = UUID()
        self.userID = userID
        self.plan = plan
        self.startDate = Date()
        self.endDate = Calendar.current.date(byAdding: plan.duration, to: Date()) ?? Date()
        self.isActive = true
        self.autoRenew = false
        self.createdAt = Date()
        
        // Set features based on plan
        switch plan {
        case .free:
            self.analyticsAccess = false
            self.prioritySupport = false
            self.unlimitedListings = false
            self.featuredListings = 0
            self.commissionRate = 5.0
        case .basic:
            self.analyticsAccess = true
            self.prioritySupport = false
            self.unlimitedListings = true
            self.featuredListings = 1
            self.commissionRate = 3.0
        case .premium:
            self.analyticsAccess = true
            self.prioritySupport = true
            self.unlimitedListings = true
            self.featuredListings = 5
            self.commissionRate = 2.0
        }
    }
}

enum SubscriptionPlan: String, CaseIterable, Codable {
    case free = "free"
    case basic = "basic"
    case premium = "premium"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .basic: return "Basic Pro"
        case .premium: return "Premium Pro"
        }
    }
    
    var price: Double {
        switch self {
        case .free: return 0.0
        case .basic: return 9.99
        case .premium: return 19.99
        }
    }
    
    var duration: DateComponents {
        switch self {
        case .free: return DateComponents(year: 100) // Effectively permanent
        case .basic: return DateComponents(month: 1)
        case .premium: return DateComponents(month: 1)
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "Up to 5 product listings",
                "Basic marketplace access",
                "Standard support",
                "5% commission on sales"
            ]
        case .basic:
            return [
                "Unlimited product listings",
                "Basic analytics dashboard",
                "Priority in search results",
                "1 featured listing per month",
                "3% commission on sales"
            ]
        case .premium:
            return [
                "Everything in Basic",
                "Advanced analytics & insights",
                "Priority customer support",
                "5 featured listings per month",
                "Early access to new features",
                "2% commission on sales"
            ]
        }
    }
    
    var maxListings: Int? {
        switch self {
        case .free: return 5
        case .basic, .premium: return nil // Unlimited
        }
    }
}
