//
//  MarketplaceView.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import SwiftUI
import SwiftData

struct MarketplaceView: View {
    let currentUser: User
    @Environment(\.modelContext) private var modelContext
    @Query private var products: [Product]
    @Query private var farmers: [User]
    
    @State private var searchText = ""
    @State private var selectedCategory: ProductCategory?
    @State private var showingFilters = false
    @State private var sortOption: SortOption = .newest
    @State private var showingAddProduct = false
    @State private var viewMode: ViewMode = .products
    
    var filteredProducts: [Product] {
        var result = products.filter { $0.isAvailable }
        
        if !searchText.isEmpty {
            result = result.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.productDescription.localizedCaseInsensitiveContains(searchText) ||
                product.location.localizedCaseInsensitiveContains(searchText) ||
                (product.farmerName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        return result.sorted { product1, product2 in
            switch sortOption {
            case .newest:
                return product1.createdAt > product2.createdAt
            case .oldest:
                return product1.createdAt < product2.createdAt
            case .priceHigh:
                return product1.price > product2.price
            case .priceLow:
                return product1.price < product2.price
            case .popular:
                return product1.views > product2.views
            }
        }
    }
    
    var filteredFarmers: [User] {
        var result = farmers.filter { $0.userType == .farmer }
        
        if !searchText.isEmpty {
            result = result.filter { farmer in
                farmer.name.localizedCaseInsensitiveContains(searchText) ||
                farmer.location.localizedCaseInsensitiveContains(searchText) ||
                (farmer.farmName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (farmer.farmDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return result
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
                            
                            TextField("Search products, farmers, locations...", text: $searchText)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        Button(action: { showingFilters = true }) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.green)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    
                    // View mode selector
                    HStack(spacing: 0) {
                        Button(action: { viewMode = .products }) {
                            Text("Products")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(viewMode == .products ? .white : .green)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(viewMode == .products ? Color.green : Color.clear)
                                .cornerRadius(8, corners: [.topLeft, .bottomLeft])
                        }
                        
                        Button(action: { viewMode = .farmers }) {
                            Text("Farmers")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(viewMode == .farmers ? .white : .green)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(viewMode == .farmers ? Color.green : Color.clear)
                                .cornerRadius(8, corners: [.topRight, .bottomRight])
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    // Category scroll (only for products view)
                    if viewMode == .products {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                CategoryButton(
                                    category: nil,
                                    isSelected: selectedCategory == nil,
                                    action: { selectedCategory = nil }
                                )
                                
                                ForEach(ProductCategory.allCases, id: \.self) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: selectedCategory == category,
                                        action: { selectedCategory = category }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Content based on view mode
                if viewMode == .products {
                    // Products grid
                    if filteredProducts.isEmpty {
                        EmptyStateView(type: .products)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(filteredProducts) { product in
                                    NavigationLink(destination: ProductDetailView(product: product, currentUser: currentUser)) {
                                        EnhancedProductCard(product: product, farmers: farmers)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    // Farmers list
                    if filteredFarmers.isEmpty {
                        EmptyStateView(type: .farmers)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredFarmers) { farmer in
                                    FarmerCardView(farmer: farmer, products: products, currentUser: currentUser)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Marketplace")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: { sortOption = option }) {
                                Label(option.displayName, systemImage: sortOption == option ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
                
                if currentUser.userType == .farmer {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showingAddProduct = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(
                    selectedCategory: $selectedCategory,
                    sortOption: $sortOption
                )
            }
            .sheet(isPresented: $showingAddProduct) {
                AddProductView(farmer: currentUser)
            }
        }
    }
}

struct CategoryButton: View {
    let category: ProductCategory?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.caption)
                    Text(category.displayName)
                        .font(.caption)
                } else {
                    Text("All")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.green : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct EnhancedProductCard: View {
    let product: Product
    let farmers: [User]
    
    var farmer: User? {
        farmers.first { $0.id == product.farmerID }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product image placeholder with farming method indicator
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: product.category.icon)
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    )
                
                if let method = product.farmingMethod {
                    HStack(spacing: 4) {
                        Image(systemName: method.icon)
                            .font(.caption2)
                        Text(method.displayName)
                            .font(.caption2)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(method == .organic ? Color.green : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .lineLimit(2)
                
                // Price with unit
                Text("$\(String(format: "%.2f", product.price))/\(product.unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                // Farmer information
                if let farmerName = product.farmerName ?? farmer?.farmName {
                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(farmerName)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                }
                
                // Location
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(product.location)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Available quantity
                    Text("\(String(format: "%.0f", product.availableQuantity)) \(product.unit)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Tags and organic indicator
                HStack {
                    if product.isOrganic {
                        Text("ORGANIC")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                        Text("\(product.views)")
                            .font(.caption2)
                    }
                    .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct FarmerCardView: View {
    let farmer: User
    let products: [Product]
    let currentUser: User
    @State private var showingFarmerDetail = false
    
    var farmerProducts: [Product] {
        products.filter { $0.farmerID == farmer.id && $0.isAvailable }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Farmer header
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(farmer.farmName ?? farmer.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if farmer.isVerified {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(farmer.location)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if let description = farmer.farmDescription {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(farmerProducts.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Products")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // Product preview
            if !farmerProducts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(farmerProducts.prefix(4)) { product in
                            NavigationLink(destination: ProductDetailView(product: product, currentUser: currentUser)) {
                                CompactProductCard(product: product)
                            }
                        }
                        
                        if farmerProducts.count > 4 {
                            Button(action: { showingFarmerDetail = true }) {
                                VStack {
                                    Text("+\(farmerProducts.count - 4)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                    Text("more")
                                        .font(.caption2)
                                }
                                .frame(width: 60, height: 60)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                                .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onTapGesture {
            showingFarmerDetail = true
        }
        .sheet(isPresented: $showingFarmerDetail) {
            FarmerDetailView(farmer: farmer, currentUser: currentUser)
        }
    }
}

struct CompactProductCard: View {
    let product: Product
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: product.category.icon)
                        .font(.caption)
                        .foregroundColor(.gray)
                )
            
            Text(product.name)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 60)
            
            Text("$\(String(format: "%.0f", product.price))")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
    }
}

struct ProductCard: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product image placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(height: 120)
                .overlay(
                    Image(systemName: product.category.icon)
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text("$\(String(format: "%.2f", product.price))/\(product.unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(product.location)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                HStack {
                    if product.isOrganic {
                        Text("ORGANIC")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                        Text("\(product.views)")
                            .font(.caption2)
                    }
                    .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct EmptyStateView: View {
    let type: EmptyStateType
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: type.icon)
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(type.title)
                .font(.headline)
            
            Text(type.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

enum EmptyStateType {
    case products
    case farmers
    
    var icon: String {
        switch self {
        case .products: return "leaf"
        case .farmers: return "person.crop.circle"
        }
    }
    
    var title: String {
        switch self {
        case .products: return "No products found"
        case .farmers: return "No farmers found"
        }
    }
    
    var subtitle: String {
        switch self {
        case .products: return "Try adjusting your search or filters"
        case .farmers: return "Try searching for farmers in your area"
        }
    }
}

enum ViewMode {
    case products
    case farmers
}

enum SortOption: String, CaseIterable {
    case newest = "newest"
    case oldest = "oldest"
    case priceHigh = "priceHigh"
    case priceLow = "priceLow"
    case popular = "popular"
    
    var displayName: String {
        switch self {
        case .newest: return "Newest First"
        case .oldest: return "Oldest First"
        case .priceHigh: return "Price: High to Low"
        case .priceLow: return "Price: Low to High"
        case .popular: return "Most Popular"
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    let user = User(name: "Test User", email: "test@example.com", phone: "123456789", userType: .consumer, location: "Chisinau")
    
    return MarketplaceView(currentUser: user)
        .modelContainer(for: [Product.self, User.self], inMemory: true)
}
