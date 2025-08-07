//
//  ProfileView.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    let currentUser: User
    @Environment(\.modelContext) private var modelContext
    @Query private var subscriptions: [Subscription]
    @Query private var products: [Product]
    @Query private var orders: [Order]
    
    @State private var showingSubscriptionSheet = false
    @State private var showingEditProfile = false
    @State private var showingAnalytics = false
    
    private var currentSubscription: Subscription? {
        subscriptions.first { $0.userID == currentUser.id && $0.isActive }
    }
    
    private var userProducts: [Product] {
        products.filter { $0.farmerID == currentUser.id }
    }
    
    private var userSales: [Order] {
        orders.filter { $0.farmerID == currentUser.id }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    ProfileHeaderView(user: currentUser, subscription: currentSubscription)
                    
                    // Stats (for farmers)
                    if currentUser.userType == .farmer {
                        FarmerStatsView(
                            productsCount: userProducts.count,
                            activeOrdersCount: userSales.filter { ![.delivered, .completed, .cancelled].contains($0.status) }.count,
                            totalSales: userSales.reduce(0) { $0 + $1.totalAmount },
                            rating: currentUser.rating
                        )
                    }
                    
                    // Subscription section
                    SubscriptionSectionView(
                        subscription: currentSubscription,
                        onUpgrade: { showingSubscriptionSheet = true }
                    )
                    
                    // Quick actions
                    QuickActionsView(
                        userType: currentUser.userType,
                        onAnalytics: { showingAnalytics = true },
                        hasAnalyticsAccess: currentSubscription?.analyticsAccess ?? false
                    )
                    
                    // Settings
                    SettingsSectionView(onEditProfile: { showingEditProfile = true })
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingEditProfile = true }) {
                        Text("Edit")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSubscriptionSheet) {
            SubscriptionManagementView(currentUser: currentUser, currentSubscription: currentSubscription)
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(user: currentUser)
        }
        .sheet(isPresented: $showingAnalytics) {
            if currentSubscription?.analyticsAccess == true {
                AnalyticsView(farmer: currentUser, products: userProducts, orders: userSales)
            }
        }
    }
}

struct ProfileHeaderView: View {
    let user: User
    let subscription: Subscription?
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile image placeholder
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: user.userType.icon)
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                )
            
            VStack(spacing: 8) {
                Text(user.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let farmName = user.farmName {
                    Text(farmName)
                        .font(.headline)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.gray)
                    Text(user.location)
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
                
                // Subscription badge
                if let subscription = subscription {
                    HStack {
                        Image(systemName: subscription.plan == .free ? "star" : "star.fill")
                            .foregroundColor(subscription.plan == .free ? .gray : .yellow)
                        Text(subscription.plan.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Verification badge
                if user.isVerified {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                        Text("Verified")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

struct FarmerStatsView: View {
    let productsCount: Int
    let activeOrdersCount: Int
    let totalSales: Double
    let rating: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(title: "Products", value: "\(productsCount)", icon: "leaf.fill", color: .green)
                StatCard(title: "Active Orders", value: "\(activeOrdersCount)", icon: "bag.fill", color: .blue)
                StatCard(title: "Total Sales", value: "$\(String(format: "%.0f", totalSales))", icon: "dollarsign.circle.fill", color: .orange)
                StatCard(title: "Rating", value: "\(String(format: "%.1f", rating))⭐", icon: "star.fill", color: .yellow)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct SubscriptionSectionView: View {
    let subscription: Subscription?
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Subscription")
                    .font(.headline)
                Spacer()
                if subscription?.plan != .premium {
                    Button("Upgrade", action: onUpgrade)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            if let subscription = subscription {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(subscription.plan.displayName)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        if subscription.plan != .free {
                            Text("$\(subscription.plan.price, specifier: "%.2f")/month")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                    
                    if subscription.plan != .free {
                        Text("Expires: \(subscription.endDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(subscription.plan.features.prefix(3), id: \.self) { feature in
                            HStack {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text(feature)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct QuickActionsView: View {
    let userType: UserType
    let onAnalytics: () -> Void
    let hasAnalyticsAccess: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if userType == .farmer {
                    ActionButton(title: "Add Product", icon: "plus.circle.fill", color: .green) {
                        // Action handled by parent view
                    }
                    
                    ActionButton(title: "Analytics", icon: "chart.bar.fill", color: .blue, isEnabled: hasAnalyticsAccess, action: onAnalytics)
                }
                
                ActionButton(title: "Support", icon: "questionmark.circle.fill", color: .orange) {
                    // Open support
                }
                
                ActionButton(title: "Share App", icon: "square.and.arrow.up.fill", color: .purple) {
                    // Share app
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var isEnabled: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: isEnabled ? action : {}) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isEnabled ? color : .gray)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isEnabled ? .primary : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .disabled(!isEnabled)
    }
}

struct SettingsSectionView: View {
    let onEditProfile: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)
            
            VStack(spacing: 0) {
                SettingsRow(title: "Edit Profile", icon: "person.fill", action: onEditProfile)
                Divider()
                SettingsRow(title: "Notifications", icon: "bell.fill") { }
                Divider()
                SettingsRow(title: "Privacy & Security", icon: "lock.fill") { }
                Divider()
                SettingsRow(title: "Help & Support", icon: "questionmark.circle.fill") { }
                Divider()
                SettingsRow(title: "About", icon: "info.circle.fill") { }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
        }
    }
}

#Preview {
    let user = User(name: "Test Farmer", email: "test@farm.com", phone: "123456789", userType: .farmer, location: "Chisinau")
    user.farmName = "Green Valley Farm"
    user.isVerified = true
    user.rating = 4.8
    
    return ProfileView(currentUser: user)
        .modelContainer(for: [User.self, Subscription.self, Product.self, Order.self], inMemory: true)
}
