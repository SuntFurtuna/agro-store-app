//
//  ProductDetailView.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import SwiftUI
import SwiftData

struct ProductDetailView: View {
    let product: Product
    let currentUser: User
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [User]
    
    @State private var quantity: Double = 1
    @State private var selectedDeliveryOption: DeliveryOption = .pickup
    @State private var showingOrderConfirmation = false
    @State private var deliveryAddress = ""
    @State private var orderNotes = ""
    
    private var farmer: User? {
        users.first { $0.id == product.farmerID }
    }
    
    private var totalPrice: Double {
        quantity * product.price
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Product images
                ProductImageCarousel(imageURLs: product.imageURLs, category: product.category)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Product header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            Text("$\(String(format: "%.2f", product.price))")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            
                            Text("per \(product.unit)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if product.isOrganic {
                                Text("ORGANIC")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    
                    // Farmer info
                    if let farmer = farmer {
                        FarmerInfoCard(farmer: farmer)
                    }
                    
                    // Product description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(product.productDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Product details
                    ProductDetailsSection(product: product)
                    
                    // Delivery options
                    if currentUser.userType != .farmer || currentUser.id != product.farmerID {
                        DeliveryOptionsSection(
                            options: product.deliveryOptions,
                            selected: $selectedDeliveryOption,
                            address: $deliveryAddress
                        )
                        
                        // Quantity selector
                        QuantitySelector(
                            quantity: $quantity,
                            unit: product.unit,
                            minimum: product.minimumOrder,
                            maximum: product.availableQuantity
                        )
                        
                        // Order notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (Optional)")
                                .font(.headline)
                            
                            TextField("Special requests or notes...", text: $orderNotes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...5)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Product Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if currentUser.userType != .farmer || currentUser.id != product.farmerID {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addToLikes) {
                        Image(systemName: "heart")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if currentUser.userType != .farmer || currentUser.id != product.farmerID {
                OrderBottomBar(
                    totalPrice: totalPrice,
                    onOrder: { showingOrderConfirmation = true }
                )
            }
        }
        .sheet(isPresented: $showingOrderConfirmation) {
            OrderConfirmationView(
                product: product,
                farmer: farmer,
                quantity: quantity,
                deliveryOption: selectedDeliveryOption,
                deliveryAddress: deliveryAddress,
                notes: orderNotes,
                totalPrice: totalPrice,
                customer: currentUser
            )
        }
        .onAppear {
            incrementViews()
            if !product.deliveryOptions.isEmpty {
                selectedDeliveryOption = product.deliveryOptions.first!
            }
        }
    }
    
    private func incrementViews() {
        product.views += 1
        try? modelContext.save()
    }
    
    private func addToLikes() {
        product.likes += 1
        try? modelContext.save()
    }
}

struct ProductImageCarousel: View {
    let imageURLs: [String]
    let category: ProductCategory
    
    var body: some View {
        TabView {
            if imageURLs.isEmpty {
                // Placeholder image
                Rectangle()
                    .fill(Color(.systemGray5))
                    .aspectRatio(1.5, contentMode: .fit)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text(category.displayName)
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                    )
            } else {
                ForEach(imageURLs, id: \.self) { imageURL in
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                ProgressView()
                            )
                    }
                }
            }
        }
        .frame(height: 300)
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

struct FarmerInfoCard: View {
    let farmer: User
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 25))
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(farmer.farmName ?? farmer.name)
                    .font(.headline)
                
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(farmer.location)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if farmer.isVerified {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Verified Farmer")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            VStack {
                Text("\(String(format: "%.1f", farmer.rating))")
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { star in
                        Image(systemName: star < Int(farmer.rating) ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
                
                Text("(\(farmer.totalReviews))")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProductDetailsSection: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Product Details")
                .font(.headline)
            
            VStack(spacing: 8) {
                DetailRow(label: "Category", value: product.category.displayName)
                DetailRow(label: "Available Quantity", value: "\(String(format: "%.0f", product.availableQuantity)) \(product.unit)")
                DetailRow(label: "Minimum Order", value: "\(String(format: "%.0f", product.minimumOrder)) \(product.unit)")
                
                if let harvestDate = product.harvestDate {
                    DetailRow(label: "Harvest Date", value: harvestDate.formatted(date: .abbreviated, time: .omitted))
                }
                
                if let expiryDate = product.expiryDate {
                    DetailRow(label: "Best Before", value: expiryDate.formatted(date: .abbreviated, time: .omitted))
                }
                
                DetailRow(label: "Location", value: product.location)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

struct DeliveryOptionsSection: View {
    let options: [DeliveryOption]
    @Binding var selected: DeliveryOption
    @Binding var address: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Delivery Options")
                .font(.headline)
            
            ForEach(options, id: \.self) { option in
                Button(action: { selected = option }) {
                    HStack {
                        Image(systemName: option.icon)
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(deliveryDescription(for: option))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selected == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
            }
            
            if selected == .delivery {
                TextField("Delivery address", text: $address)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func deliveryDescription(for option: DeliveryOption) -> String {
        switch option {
        case .pickup: return "Pick up directly from the farm"
        case .delivery: return "Local delivery available"
        case .shipping: return "Shipped to your location"
        }
    }
}

struct QuantitySelector: View {
    @Binding var quantity: Double
    let unit: String
    let minimum: Double
    let maximum: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quantity")
                .font(.headline)
            
            HStack {
                Button(action: { decreaseQuantity() }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(quantity > minimum ? .blue : .gray)
                }
                .disabled(quantity <= minimum)
                
                Spacer()
                
                VStack {
                    Text("\(String(format: "%.0f", quantity))")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { increaseQuantity() }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(quantity < maximum ? .blue : .gray)
                }
                .disabled(quantity >= maximum)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Text("Min: \(String(format: "%.0f", minimum)) • Available: \(String(format: "%.0f", maximum))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func increaseQuantity() {
        if quantity < maximum {
            quantity += 1
        }
    }
    
    private func decreaseQuantity() {
        if quantity > minimum {
            quantity -= 1
        }
    }
}

struct OrderBottomBar: View {
    let totalPrice: Double
    let onOrder: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Total")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("$\(String(format: "%.2f", totalPrice))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            Button(action: onOrder) {
                Text("Place Order")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
    }
}

#Preview {
    let user = User(name: "Test User", email: "test@example.com", phone: "123456789", userType: .consumer, location: "Chisinau")
    let farmer = User(name: "Test Farmer", email: "farmer@test.com", phone: "987654321", userType: .farmer, location: "Orhei")
    farmer.farmName = "Green Valley Farm"
    farmer.isVerified = true
    farmer.rating = 4.8
    farmer.totalReviews = 47
    
    let product = Product(name: "Organic Tomatoes", description: "Fresh, locally grown organic tomatoes. Perfect for salads and cooking.", category: .vegetables, price: 15.0, unit: "kg", farmerID: farmer.id, location: "Orhei")
    product.isOrganic = true
    product.availableQuantity = 50
    product.minimumOrder = 2
    product.deliveryOptions = [.pickup, .delivery]
    product.harvestDate = Date()
    
    return NavigationView {
        ProductDetailView(product: product, currentUser: user)
    }
    .modelContainer(for: [Product.self, User.self], inMemory: true)
}
