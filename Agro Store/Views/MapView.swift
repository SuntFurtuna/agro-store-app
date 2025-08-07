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
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 47.0105, longitude: 28.8638), // Chisinau, Moldova
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @State private var selectedProduct: Product?
    @State private var showingProductDetail = false
    @State private var mapType: MapType = .farmers
    
    var filteredFarmers: [User] {
        farmers.filter { $0.userType == .farmer && $0.latitude != nil && $0.longitude != nil }
    }
    
    var availableProducts: [Product] {
        products.filter { $0.isAvailable && $0.latitude != nil && $0.longitude != nil }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: mapType == .farmers ? [] : availableProducts) { product in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(
                        latitude: product.latitude ?? 0,
                        longitude: product.longitude ?? 0
                    )) {
                        ProductMapPin(product: product) {
                            selectedProduct = product
                            showingProductDetail = true
                        }
                    }
                }
                .overlay(
                    // Farmer pins overlay
                    ForEach(mapType == .farmers ? filteredFarmers : [], id: \.id) { farmer in
                        if let lat = farmer.latitude, let lon = farmer.longitude {
                            FarmerMapPin(farmer: farmer)
                                .position(
                                    x: coordinateToPoint(lat: lat, lon: lon).x,
                                    y: coordinateToPoint(lat: lat, lon: lon).y
                                )
                        }
                    }
                )
                
                // Map type selector
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            MapTypeButton(
                                title: "Farmers",
                                icon: "person.crop.circle.fill",
                                isSelected: mapType == .farmers,
                                action: { mapType = .farmers }
                            )
                            
                            MapTypeButton(
                                title: "Products",
                                icon: "leaf.fill",
                                isSelected: mapType == .products,
                                action: { mapType = .products }
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
        .onAppear {
            loadSampleData()
        }
    }
    
    private func coordinateToPoint(lat: Double, lon: Double) -> CGPoint {
        // This is a simplified conversion - in a real app you'd use proper map projection
        let x = (lon - region.center.longitude) / region.span.longitudeDelta * 300 + 200
        let y = (region.center.latitude - lat) / region.span.latitudeDelta * 300 + 200
        return CGPoint(x: x, y: y)
    }
    
    private func centerOnUserLocation() {
        // In a real app, you'd request location permission and use actual location
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 47.0105, longitude: 28.8638),
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )
    }
    
    private func loadSampleData() {
        // Add some sample data if none exists
        if farmers.isEmpty {
            let sampleFarmer = User(name: "Maria's Organic Farm", email: "maria@farm.com", phone: "123456789", userType: .farmer, location: "Orhei")
            sampleFarmer.latitude = 47.3831
            sampleFarmer.longitude = 28.8212
            sampleFarmer.farmName = "Maria's Organic Farm"
            sampleFarmer.farmDescription = "Organic vegetables and herbs"
            modelContext.insert(sampleFarmer)
            
            let product = Product(name: "Fresh Tomatoes", description: "Organic cherry tomatoes", category: .vegetables, price: 15.0, unit: "kg", farmerID: sampleFarmer.id, location: "Orhei")
            product.latitude = 47.3831
            product.longitude = 28.8212
            product.isOrganic = true
            product.availableQuantity = 50
            modelContext.insert(product)
            
            try? modelContext.save()
        }
    }
}

struct ProductMapPin: View {
    let product: Product
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Image(systemName: product.category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.green)
                    .clipShape(Circle())
                    .shadow(radius: 2)
                
                Text("$\(String(format: "%.0f", product.price))")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
    }
}

struct FarmerMapPin: View {
    let farmer: User
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 35, height: 35)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 2)
            
            if let farmName = farmer.farmName {
                Text(farmName)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .lineLimit(1)
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

#Preview {
    let user = User(name: "Test User", email: "test@example.com", phone: "123456789", userType: .consumer, location: "Chisinau")
    
    return MapView(currentUser: user)
        .modelContainer(for: [Product.self, User.self], inMemory: true)
}
