//
//  ContentView.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var currentUser: User?
    @State private var showingOnboarding = true
    
    var body: some View {
        Group {
            if showingOnboarding || currentUser == nil {
                OnboardingView(currentUser: $currentUser, showingOnboarding: $showingOnboarding)
            } else {
                MainTabView(currentUser: currentUser!)
            }
        }
        .onAppear {
            checkForExistingUser()
            addMockDataIfNeeded()
        }
    }
    
    private func checkForExistingUser() {
        // In a real app, you'd check for stored user credentials
        // For now, we'll show onboarding
        showingOnboarding = true
    }
    
    private func addMockDataIfNeeded() {
        // Check if we already have products
        let descriptor = FetchDescriptor<Product>()
        let existingProducts = try? modelContext.fetch(descriptor)
        
        if existingProducts?.isEmpty == true {
            createMockData()
        }
    }
    
    private func createMockData() {
        // Create mock farmers
        let farmer1 = User(name: "Maria Popescu", email: "maria@greenfarm.md", phone: "+37369123456", userType: .farmer, location: "Orhei")
        farmer1.farmName = "Green Valley Farm"
        farmer1.isVerified = true
        farmer1.rating = 4.8
        farmer1.totalReviews = 47
        farmer1.latitude = 47.3833  // Orhei coordinates
        farmer1.longitude = 28.8167
        
        let farmer2 = User(name: "Ion Cojocaru", email: "ion@organicfresh.md", phone: "+37369654321", userType: .farmer, location: "Căușeni")
        farmer2.farmName = "Organic Fresh"
        farmer2.isVerified = true
        farmer2.rating = 4.6
        farmer2.totalReviews = 23
        farmer2.latitude = 46.6333  // Căușeni coordinates
        farmer2.longitude = 29.4000
        
        let farmer3 = User(name: "Elena Rusu", email: "elena@sunnyacres.md", phone: "+37369987654", userType: .farmer, location: "Ungheni")
        farmer3.farmName = "Sunny Acres"
        farmer3.isVerified = true
        farmer3.rating = 4.9
        farmer3.totalReviews = 65
        farmer3.latitude = 47.2167  // Ungheni coordinates
        farmer3.longitude = 27.8000
        
        // Add farmers to context
        modelContext.insert(farmer1)
        modelContext.insert(farmer2)
        modelContext.insert(farmer3)
        
        // Create mock products
        let products = [
            // Vegetables
            Product(name: "Organic Tomatoes", description: "Fresh, juicy organic tomatoes grown without pesticides. Perfect for salads and cooking.", category: .vegetables, price: 25.0, unit: "kg", farmerID: farmer1.id, farmerName: farmer1.farmName ?? farmer1.name, location: "Orhei"),
            Product(name: "Fresh Cucumbers", description: "Crisp and refreshing cucumbers, perfect for summer salads.", category: .vegetables, price: 18.0, unit: "kg", farmerID: farmer1.id, farmerName: farmer1.farmName ?? farmer1.name, location: "Orhei"),
            Product(name: "Sweet Bell Peppers", description: "Colorful sweet bell peppers in red, yellow, and green varieties.", category: .vegetables, price: 35.0, unit: "kg", farmerID: farmer2.id, farmerName: farmer2.farmName ?? farmer2.name, location: "Căușeni"),
            Product(name: "Baby Carrots", description: "Sweet and tender baby carrots, great for snacking or cooking.", category: .vegetables, price: 22.0, unit: "kg", farmerID: farmer2.id, farmerName: farmer2.farmName ?? farmer2.name, location: "Căușeni"),
            Product(name: "Fresh Lettuce", description: "Crispy green lettuce leaves, perfect for salads and sandwiches.", category: .vegetables, price: 15.0, unit: "pieces", farmerID: farmer3.id, farmerName: farmer3.farmName ?? farmer3.name, location: "Ungheni"),
            
            // Fruits
            Product(name: "Sweet Apples", description: "Delicious red apples with crispy texture and sweet taste.", category: .fruits, price: 20.0, unit: "kg", farmerID: farmer1.id, farmerName: farmer1.farmName ?? farmer1.name, location: "Orhei"),
            Product(name: "Fresh Strawberries", description: "Sweet and juicy strawberries, freshly picked this morning.", category: .fruits, price: 45.0, unit: "kg", farmerID: farmer3.id, farmerName: farmer3.farmName ?? farmer3.name, location: "Ungheni"),
            Product(name: "Organic Grapes", description: "Sweet organic grapes, perfect for eating fresh or making juice.", category: .fruits, price: 40.0, unit: "kg", farmerID: farmer2.id, farmerName: farmer2.farmName ?? farmer2.name, location: "Căușeni"),
            
            // Dairy
            Product(name: "Fresh Cow Milk", description: "Fresh, pasteurized cow milk from grass-fed cows.", category: .dairy, price: 12.0, unit: "liter", farmerID: farmer1.id, farmerName: farmer1.farmName ?? farmer1.name, location: "Orhei"),
            Product(name: "Artisan Cheese", description: "Handmade cheese with traditional methods and natural ingredients.", category: .dairy, price: 80.0, unit: "kg", farmerID: farmer3.id, farmerName: farmer3.farmName ?? farmer3.name, location: "Ungheni"),
            
            // Eggs
            Product(name: "Free-Range Eggs", description: "Fresh eggs from free-range chickens, rich in nutrients.", category: .eggs, price: 25.0, unit: "dozen", farmerID: farmer2.id, farmerName: farmer2.farmName ?? farmer2.name, location: "Căușeni"),
            
            // Honey
            Product(name: "Wildflower Honey", description: "Pure wildflower honey with natural sweetness and health benefits.", category: .honey, price: 120.0, unit: "kg", farmerID: farmer1.id, farmerName: farmer1.farmName ?? farmer1.name, location: "Orhei"),
            
            // Herbs
            Product(name: "Fresh Basil", description: "Aromatic fresh basil leaves, perfect for cooking and garnishing.", category: .herbs, price: 60.0, unit: "kg", farmerID: farmer3.id, farmerName: farmer3.farmName ?? farmer3.name, location: "Ungheni"),
            Product(name: "Organic Parsley", description: "Fresh organic parsley, rich in vitamins and perfect for cooking.", category: .herbs, price: 40.0, unit: "kg", farmerID: farmer2.id, farmerName: farmer2.farmName ?? farmer2.name, location: "Căușeni"),
            
            // Grains
            Product(name: "Organic Wheat", description: "High-quality organic wheat, perfect for baking and cooking.", category: .grains, price: 8.0, unit: "kg", farmerID: farmer1.id, farmerName: farmer1.farmName ?? farmer1.name, location: "Orhei")
        ]
        
        // Configure each product
        for product in products {
            product.isOrganic = Bool.random()
            product.availableQuantity = Double.random(in: 10...100)
            product.minimumOrder = Double.random(in: 1...5)
            product.deliveryOptions = [.pickup, .delivery].shuffled().prefix(Int.random(in: 1...2)).map { $0 }
            product.harvestDate = Calendar.current.date(byAdding: .day, value: -Int.random(in: 1...7), to: Date())
            product.views = Int.random(in: 0...100)
            product.likes = Int.random(in: 0...50)
            product.tags = ["fresh", "local", "seasonal"].shuffled().prefix(Int.random(in: 1...3)).map { $0 }
            
            // Set product coordinates based on farmer location
            if product.farmerID == farmer1.id {
                product.latitude = farmer1.latitude! + Double.random(in: -0.01...0.01)
                product.longitude = farmer1.longitude! + Double.random(in: -0.01...0.01)
            } else if product.farmerID == farmer2.id {
                product.latitude = farmer2.latitude! + Double.random(in: -0.01...0.01)
                product.longitude = farmer2.longitude! + Double.random(in: -0.01...0.01)
            } else if product.farmerID == farmer3.id {
                product.latitude = farmer3.latitude! + Double.random(in: -0.01...0.01)
                product.longitude = farmer3.longitude! + Double.random(in: -0.01...0.01)
            }
            
            modelContext.insert(product)
        }
        
        // Save the context
        do {
            try modelContext.save()
            print("Mock data created successfully!")
        } catch {
            print("Failed to save mock data: \(error)")
        }
    }
}

struct MainTabView: View {
    let currentUser: User
    
    var body: some View {
        TabView {
            MarketplaceView(currentUser: currentUser)
                .tabItem {
                    Image(systemName: "storefront.fill")
                    Text("Marketplace")
                }
            
            CartView(currentUser: currentUser)
                .tabItem {
                    Image(systemName: "cart.fill")
                    Text("Cart")
                }
            
            DemandsView(currentUser: currentUser)
                .tabItem {
                    Image(systemName: "exclamationmark.bubble.fill")
                    Text("Demands")
                }
            
            MapView(currentUser: currentUser)
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Map")
                }
            
            OrdersView(currentUser: currentUser)
                .tabItem {
                    Image(systemName: "bag.fill")
                    Text("Orders")
                }
            
            ProfileView(currentUser: currentUser)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.green)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [User.self, Product.self, Order.self, OrderItem.self, CartItem.self, DemandRequest.self, RequestResponse.self, Subscription.self], inMemory: true)
}
