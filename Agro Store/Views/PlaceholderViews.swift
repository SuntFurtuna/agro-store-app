//
//  PlaceholderViews.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import SwiftUI
import SwiftData

// MARK: - Missing Views for Compilation

struct DemandDetailView: View {
    let demand: DemandRequest
    let currentUser: User
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(demand.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(demand.requestDescription)
                    .font(.body)
                
                // Add more demand details here
            }
            .padding()
        }
        .navigationTitle("Demand Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddDemandView: View {
    let requester: User
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add Demand Request")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Add form fields here
                
                Spacer()
            }
            .padding()
            .navigationTitle("Post Demand")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") { dismiss() }
                }
            }
        }
    }
}

struct OrderDetailView: View {
    let order: Order
    let currentUser: User
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Order #\(order.id.uuidString.prefix(8))")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Total: $\(order.totalAmount, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.green)
                
                // Add more order details here
            }
            .padding()
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OrderConfirmationView: View {
    let product: Product
    let farmer: User?
    let quantity: Double
    let deliveryOption: DeliveryOption
    let deliveryAddress: String
    let notes: String
    let totalPrice: Double
    let customer: User
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Confirm Your Order")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Product: \(product.name)")
                        Text("Quantity: \(quantity, specifier: "%.0f") \(product.unit)")
                        Text("Price: $\(totalPrice, specifier: "%.2f")")
                        Text("Delivery: \(deliveryOption.displayName)")
                        
                        if !deliveryAddress.isEmpty {
                            Text("Address: \(deliveryAddress)")
                        }
                        
                        if !notes.isEmpty {
                            Text("Notes: \(notes)")
                        }
                    }
                    .font(.body)
                    
                    Button("Confirm Order") {
                        confirmOrder()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding()
            }
            .navigationTitle("Confirm Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func confirmOrder() {
        guard let farmer = farmer else { return }
        
        let orderItem = OrderItem(
            productID: product.id,
            productName: product.name,
            quantity: quantity,
            unitPrice: product.price
        )
        
        let order = Order(
            customerID: customer.id,
            farmerID: farmer.id,
            items: [orderItem],
            totalAmount: totalPrice,
            deliveryOption: deliveryOption
        )
        
        if !deliveryAddress.isEmpty {
            order.deliveryAddress = deliveryAddress
        }
        
        if !notes.isEmpty {
            order.notes = notes
        }
        
        order.deliveryDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())
        
        modelContext.insert(order)
        try? modelContext.save()
        
        dismiss()
    }
}

struct EditProfileView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Profile Information") {
                    Text("Name: \(user.name)")
                    Text("Email: \(user.email)")
                    Text("Location: \(user.location)")
                    
                    if let farmName = user.farmName {
                        Text("Farm: \(farmName)")
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { dismiss() }
                }
            }
        }
    }
}

struct AnalyticsView: View {
    let farmer: User
    let products: [Product]
    let orders: [Order]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Analytics Dashboard")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        AnalyticsCard(title: "Total Products", value: "\(products.count)", color: .green)
                        AnalyticsCard(title: "Total Orders", value: "\(orders.count)", color: .blue)
                        AnalyticsCard(title: "Revenue", value: "$\(String(format: "%.0f", orders.reduce(0) { $0 + $1.totalAmount }))", color: .orange)
                        AnalyticsCard(title: "Avg Rating", value: "\(String(format: "%.1f", farmer.rating))⭐", color: .yellow)
                    }
                    
                    // Add charts and more analytics here
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    let user = User(name: "Test User", email: "test@example.com", phone: "123456789", userType: .consumer, location: "Chisinau")
    let demand = DemandRequest(
        requesterID: user.id,
        title: "Fresh Tomatoes",
        description: "Need fresh tomatoes for restaurant",
        category: .vegetables,
        quantity: 20,
        unit: "kg",
        maxPrice: 25.0,
        location: "Chisinau",
        requiredBy: Date()
    )
    
    return DemandDetailView(demand: demand, currentUser: user)
        .modelContainer(for: [DemandRequest.self], inMemory: true)
}
