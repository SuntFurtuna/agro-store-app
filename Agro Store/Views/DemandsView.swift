//
//  DemandsView.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import SwiftUI
import SwiftData

struct DemandsView: View {
    let currentUser: User
    @Environment(\.modelContext) private var modelContext
    @Query private var demands: [DemandRequest]
    
    @State private var showingAddDemand = false
    @State private var selectedFilter: DemandFilter = .all
    @State private var searchText = ""
    
    var filteredDemands: [DemandRequest] {
        var result = demands
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { demand in
                demand.title.localizedCaseInsensitiveContains(searchText) ||
                demand.requestDescription.localizedCaseInsensitiveContains(searchText) ||
                demand.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by status
        switch selectedFilter {
        case .all:
            break
        case .open:
            result = result.filter { $0.status == .open }
        case .myDemands:
            result = result.filter { $0.requesterID == currentUser.id }
        case .canFulfill:
            if currentUser.userType == .farmer {
                result = result.filter { $0.status == .open }
            }
        }
        
        return result.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filters
                VStack(spacing: 12) {
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search demands...", text: $searchText)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Filter tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(DemandFilter.allCases, id: \.self) { filter in
                                FilterTab(
                                    title: filter.displayName,
                                    isSelected: selectedFilter == filter,
                                    action: { selectedFilter = filter }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Demands list
                if filteredDemands.isEmpty {
                    EmptyDemandsView(filter: selectedFilter)
                } else {
                    List(filteredDemands) { demand in
                        NavigationLink(destination: DemandDetailView(demand: demand, currentUser: currentUser)) {
                            DemandCard(demand: demand, currentUser: currentUser)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Market Demands")
            .toolbar {
                if currentUser.userType == .restaurant || currentUser.userType == .retailer {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddDemand = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddDemand) {
                AddDemandView(requester: currentUser)
            }
        }
        .onAppear {
            loadSampleDemands()
        }
    }
    
    private func loadSampleDemands() {
        if demands.isEmpty {
            let restaurant = User(name: "Villa Mia Restaurant", email: "villa@mia.com", phone: "123456789", userType: .restaurant, location: "Chisinau")
            modelContext.insert(restaurant)
            
            let demand = DemandRequest(
                requesterID: restaurant.id,
                title: "Fresh Organic Tomatoes Needed",
                description: "Looking for 20kg of fresh organic tomatoes for our weekly menu. Must be locally grown and pesticide-free.",
                category: .vegetables,
                quantity: 20,
                unit: "kg",
                maxPrice: 25.0,
                location: "Chisinau",
                requiredBy: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            )
            demand.isOrganic = true
            demand.isUrgent = false
            modelContext.insert(demand)
            
            try? modelContext.save()
        }
    }
}

struct DemandCard: View {
    let demand: DemandRequest
    let currentUser: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(demand.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    HStack {
                        Image(systemName: demand.category.icon)
                            .foregroundColor(.green)
                        Text(demand.category.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: demand.status)
                    
                    if demand.isUrgent {
                        Text("URGENT")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
            }
            
            // Details
            VStack(alignment: .leading, spacing: 8) {
                Text(demand.requestDescription)
                    .font(.body)
                    .lineLimit(3)
                
                HStack {
                    Label("\(demand.quantity, specifier: "%.0f") \(demand.unit)", systemImage: "scale.3d")
                    
                    Spacer()
                    
                    Label("Up to $\(demand.maxPrice, specifier: "%.2f")", systemImage: "dollarsign.circle")
                        .foregroundColor(.green)
                }
                .font(.subheadline)
                
                HStack {
                    Label(demand.location, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Label("Due \(demand.requiredBy, style: .date)", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if demand.isOrganic {
                    HStack {
                        Text("ORGANIC REQUIRED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                        
                        Spacer()
                    }
                }
            }
            
            // Actions
            if currentUser.userType == .farmer && demand.status == .open {
                HStack {
                    Spacer()
                    Text("Tap to respond")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct StatusBadge: View {
    let status: RequestStatus
    
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

struct FilterTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct EmptyDemandsView: View {
    let filter: DemandFilter
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.bubble")
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
        switch filter {
        case .all: return "No demands posted yet"
        case .open: return "No open demands"
        case .myDemands: return "You haven't posted any demands"
        case .canFulfill: return "No demands you can fulfill"
        }
    }
    
    private var emptySubtitle: String {
        switch filter {
        case .all: return "Be the first to post what you're looking for"
        case .open: return "Check back later for new opportunities"
        case .myDemands: return "Post a demand to find what you need"
        case .canFulfill: return "No matching demands for your products"
        }
    }
}

enum DemandFilter: CaseIterable {
    case all
    case open
    case myDemands
    case canFulfill
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .open: return "Open"
        case .myDemands: return "My Demands"
        case .canFulfill: return "Can Fulfill"
        }
    }
}

#Preview {
    let user = User(name: "Test Restaurant", email: "test@restaurant.com", phone: "123456789", userType: .restaurant, location: "Chisinau")
    
    return DemandsView(currentUser: user)
        .modelContainer(for: [DemandRequest.self, User.self], inMemory: true)
}
