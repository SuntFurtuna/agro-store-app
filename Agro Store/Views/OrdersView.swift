//
//  OrdersView.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import SwiftUI
import SwiftData

struct OrdersView: View {
    let currentUser: User
    @Environment(\.modelContext) private var modelContext
    @Query private var orders: [Order]
    
    @State private var selectedTab: OrderTab = .active
    
    var filteredOrders: [Order] {
        let userOrders = orders.filter { order in
            if currentUser.userType == .farmer {
                return order.farmerID == currentUser.id
            } else {
                return order.customerID == currentUser.id
            }
        }
        
        switch selectedTab {
        case .active:
            return userOrders.filter { ![.delivered, .completed, .cancelled].contains($0.status) }
        case .completed:
            return userOrders.filter { [.delivered, .completed].contains($0.status) }
        case .cancelled:
            return userOrders.filter { $0.status == .cancelled }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                HStack(spacing: 0) {
                    ForEach(OrderTab.allCases, id: \.self) { tab in
                        Button(action: { selectedTab = tab }) {
                            VStack(spacing: 4) {
                                Text(tab.displayName)
                                    .font(.subheadline)
                                    .fontWeight(selectedTab == tab ? .semibold : .regular)
                                
                                Rectangle()
                                    .fill(selectedTab == tab ? Color.green : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .foregroundColor(selectedTab == tab ? .green : .gray)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .background(Color(.systemBackground))
                
                Divider()
                
                // Orders list
                if filteredOrders.isEmpty {
                    EmptyOrdersView(tab: selectedTab, userType: currentUser.userType)
                } else {
                    List(filteredOrders.sorted { $0.createdAt > $1.createdAt }) { order in
                        NavigationLink(destination: OrderDetailView(order: order, currentUser: currentUser)) {
                            OrderCard(order: order, currentUser: currentUser)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle(currentUser.userType == .farmer ? "My Sales" : "My Orders")
        }
        .onAppear {
            loadSampleOrders()
        }
    }
    
    private func loadSampleOrders() {
        if orders.isEmpty && currentUser.userType == .consumer {
            let farmer = User(name: "Green Valley Farm", email: "green@valley.com", phone: "123456789", userType: .farmer, location: "Orhei")
            modelContext.insert(farmer)
            
            let orderItem = OrderItem(productID: UUID(), productName: "Organic Tomatoes", quantity: 5, unitPrice: 15.0)
            
            let order = Order(
                customerID: currentUser.id,
                farmerID: farmer.id,
                items: [orderItem],
                totalAmount: 75.0,
                deliveryOption: .delivery
            )
            order.status = .confirmed
            order.deliveryAddress = "123 Main St, Chisinau"
            order.deliveryDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())
            
            modelContext.insert(order)
            try? modelContext.save()
        }
    }
}

struct OrderCard: View {
    let order: Order
    let currentUser: User
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    private var otherParty: User? {
        if currentUser.userType == .farmer {
            return users.first { $0.id == order.customerID }
        } else {
            return users.first { $0.id == order.farmerID }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order #\(order.id.uuidString.prefix(8))")
                        .font(.headline)
                    
                    if let party = otherParty {
                        Text(currentUser.userType == .farmer ? "Customer: \(party.name)" : "From: \(party.farmName ?? party.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    OrderStatusBadge(status: order.status)
                    Text("$\(String(format: "%.2f", order.totalAmount))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            // Items
            VStack(alignment: .leading, spacing: 4) {
                ForEach(order.items, id: \.id) { item in
                    HStack {
                        Text(item.productName)
                            .font(.body)
                        Spacer()
                        Text("\(String(format: "%.0f", item.quantity)) × $\(String(format: "%.2f", item.unitPrice))")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Delivery info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: order.deliveryOption.icon)
                        .foregroundColor(.blue)
                    Text(order.deliveryOption.displayName)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    if let deliveryDate = order.deliveryDate {
                        Text(deliveryDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let address = order.deliveryAddress {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Action buttons for farmers
            if currentUser.userType == .farmer && order.status == .pending {
                HStack(spacing: 12) {
                    Button("Accept") {
                        order.status = .confirmed
                        try? modelContext.save()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button("Decline") {
                        order.status = .cancelled
                        try? modelContext.save()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
            
            // Progress indicator
            if order.status != .cancelled {
                OrderProgressView(status: order.status)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct OrderStatusBadge: View {
    let status: OrderStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(status.color).opacity(0.2))
            .foregroundColor(Color(status.color))
            .cornerRadius(8)
    }
}

struct OrderProgressView: View {
    let status: OrderStatus
    
    private let progressSteps: [OrderStatus] = [.pending, .confirmed, .preparing, .ready, .delivered]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Order Progress")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                ForEach(Array(progressSteps.enumerated()), id: \.offset) { index, step in
                    Circle()
                        .fill(currentStepIndex >= index ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    if index < progressSteps.count - 1 {
                        Rectangle()
                            .fill(currentStepIndex > index ? Color.green : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
        }
    }
    
    private var currentStepIndex: Int {
        progressSteps.firstIndex(of: status) ?? 0
    }
}

struct EmptyOrdersView: View {
    let tab: OrderTab
    let userType: UserType
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bag")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(emptyMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(emptySubtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyMessage: String {
        switch (tab, userType) {
        case (.active, .farmer): return "No active sales"
        case (.active, _): return "No active orders"
        case (.completed, .farmer): return "No completed sales"
        case (.completed, _): return "No completed orders"
        case (.cancelled, .farmer): return "No cancelled sales"
        case (.cancelled, _): return "No cancelled orders"
        }
    }
    
    private var emptySubtitle: String {
        switch (tab, userType) {
        case (.active, .farmer): return "When customers place orders, they'll appear here"
        case (.active, _): return "Start shopping to see your orders here"
        case (.completed, _): return "Your completed transactions will appear here"
        case (.cancelled, _): return "Any cancelled orders will appear here"
        }
    }
}

enum OrderTab: CaseIterable {
    case active
    case completed
    case cancelled
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

#Preview {
    let user = User(name: "Test User", email: "test@example.com", phone: "123456789", userType: .consumer, location: "Chisinau")
    
    return OrdersView(currentUser: user)
        .modelContainer(for: [Order.self, OrderItem.self, User.self], inMemory: true)
}
