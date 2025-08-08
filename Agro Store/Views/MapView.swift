//
//  MapView.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    let currentUser: User
    @Environment(\.modelContext) private var modelContext
    @Query private var products: [Product]
    @Query private var farmers: [User]
    @Query private var farmerProfiles: [Farmer]
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 47.0105, longitude: 28.8638), // Chisinau, Moldova
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @State private var selectedProduct: Product?
    @State private var selectedFarmer: User?
    @State private var showingProductDetail = false
    @State private var showingFarmerDetail = false
    @State private var mapType: MapType = .products
    @State private var showingMapInfo = false
    
    var filteredFarmers: [User] {
        farmers.filter { farmer in
            farmer.userType == .farmer &&
            farmer.latitude != nil &&
            farmer.longitude != nil &&
            farmer.latitude! >= -90 && farmer.latitude! <= 90 &&
            farmer.longitude! >= -180 && farmer.longitude! <= 180
        }
    }
    
    var availableProducts: [Product] {
        products.filter { product in
            product.isAvailable &&
            product.latitude != nil &&
            product.longitude != nil &&
            product.latitude! >= -90 && product.latitude! <= 90 &&
            product.longitude! >= -180 && product.longitude! <= 180
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Single Map view that shows either products or farmers based on mapType
                if mapType == .products {
                    Map(coordinateRegion: $region, annotationItems: availableProducts) { product in
                        MapAnnotation(coordinate: CLLocationCoordinate2D(
                            latitude: product.latitude ?? 47.0105,
                            longitude: product.longitude ?? 28.8638
                        )) {
                            ProductMapPin(product: product) {
                                selectedProduct = product
                                showingProductDetail = true
                            }
                        }
                    }
                } else {
                    Map(coordinateRegion: $region, annotationItems: filteredFarmers) { farmer in
                        MapAnnotation(coordinate: CLLocationCoordinate2D(
                            latitude: farmer.latitude ?? 47.0105,
                            longitude: farmer.longitude ?? 28.8638
                        )) {
                            FarmerMapPin(farmer: farmer) {
                                selectedFarmer = farmer
                                showingFarmerDetail = true
                            }
                        }
                    }
                }
                
                // Map type selector
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            MapTypeButton(
                                title: "Products",
                                icon: "leaf.fill",
                                isSelected: mapType == .products,
                                action: { mapType = .products }
                            )
                            
                            MapTypeButton(
                                title: "Farmers",
                                icon: "person.crop.circle.fill",
                                isSelected: mapType == .farmers,
                                action: { mapType = .farmers }
                            )
                            
                            MapTypeButton(
                                title: "Info",
                                icon: "info.circle.fill",
                                isSelected: false,
                                action: { showingMapInfo = true }
                            )
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 4)
                        .padding(.trailing)
                    }
                    Spacer()
                }
                .padding(.top, 100)
                
                // Legend
                VStack {
                    Spacer()
                    HStack {
                        MapLegendView(mapType: mapType)
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Farm Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: centerOnUserLocation) {
                        Image(systemName: "location.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showingProductDetail) {
            if let product = selectedProduct {
                ProductDetailView(product: product, currentUser: currentUser)
            }
        }
        .sheet(isPresented: $showingFarmerDetail) {
            if let farmer = selectedFarmer {
                FarmerDetailView(farmer: farmer, currentUser: currentUser)
            }
        }
        .sheet(isPresented: $showingMapInfo) {
            MapInfoView(
                totalProducts: availableProducts.count,
                totalFarmers: filteredFarmers.count,
                mapType: mapType
            )
        }
        .onAppear {
            // Ensure region is properly set
            if region.center.latitude == 0 && region.center.longitude == 0 {
                region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 47.0105, longitude: 28.8638),
                    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                )
            }
        }
    }
    
    private func centerOnUserLocation() {
        // In a real app, you'd request location permission and use actual location
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 47.0105, longitude: 28.8638),
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )
    }
}

struct ProductMapPin: View {
    let product: Product
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 35, height: 35)
                    
                    VStack(spacing: 1) {
                        Image(systemName: product.category.icon)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        
                        if let method = product.farmingMethod, method == .organic {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                        }
                    }
                }
                .shadow(radius: 3)
                
                VStack(spacing: 1) {
                    Text("$\(String(format: "%.0f", product.price))")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    if let farmerName = product.farmerName {
                        Text(farmerName)
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: 60)
                    }
                }
            }
        }
    }
}

struct FarmerMapPin: View {
    let farmer: User
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .shadow(radius: 3)
                
                VStack(spacing: 1) {
                    if let farmName = farmer.farmName {
                        Text(farmName)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .lineLimit(1)
                            .frame(maxWidth: 80)
                    }
                    
                    Text(farmer.location)
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
        }
    }
}

struct MapTypeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .green : .gray)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? Color.green.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
    }
}

struct MapLegendView: View {
    let mapType: MapType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legend")
                .font(.caption)
                .fontWeight(.bold)
            
            if mapType == .farmers {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                    Text("Farmers")
                        .font(.caption2)
                }
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    Text("Products")
                        .font(.caption2)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

enum MapType {
    case farmers
    case products
}

struct FarmerDetailView: View {
    let farmer: User
    let currentUser: User
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var products: [Product]
    
    var farmerProducts: [Product] {
        products.filter { $0.farmerID == farmer.id && $0.isAvailable }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Farmer Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(farmer.farmName ?? farmer.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(farmer.location)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                if farmer.isVerified {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Verified Farmer")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        
                        if let description = farmer.farmDescription {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Products Section
                    if !farmerProducts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Available Products (\(farmerProducts.count))")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(farmerProducts, id: \.id) { product in
                                    MapProductCard(product: product)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Contact Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contact Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.blue)
                                Text(farmer.email)
                                Spacer()
                            }
                            
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.blue)
                                Text(farmer.phone)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Farmer Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MapProductCard: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: product.category.icon)
                    .font(.title2)
                    .foregroundColor(.green)
                Spacer()
                Text("$\(String(format: "%.1f", product.price))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            Text(product.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            Text(product.productDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                if product.isOrganic {
                    Text("Organic")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Text("\(String(format: "%.0f", product.availableQuantity)) \(product.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct MapInfoView: View {
    let totalProducts: Int
    let totalFarmers: Int
    let mapType: MapType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Farm Map Overview")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Discover local farmers and fresh products in your area")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    MapStatCard(
                        icon: "leaf.fill",
                        title: "Products Available",
                        value: "\(totalProducts)",
                        color: .green
                    )
                    
                    MapStatCard(
                        icon: "person.crop.circle.fill",
                        title: "Local Farmers",
                        value: "\(totalFarmers)",
                        color: .blue
                    )
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("How to use the map:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                            Text("Green pins show available products")
                                .font(.subheadline)
                        }
                        
                        HStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                            Text("Blue pins show farmer locations")
                                .font(.subheadline)
                        }
                        
                        HStack {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(.gray)
                            Text("Tap any pin for more details")
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Map Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MapStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    let user = User(name: "Test User", email: "test@example.com", phone: "123456789", userType: .consumer, location: "Chisinau")
    
    return MapView(currentUser: user)
        .modelContainer(for: [Product.self, User.self], inMemory: true)
}
