//
//  AddProductView.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import SwiftUI
import SwiftData

struct AddProductView: View {
    let farmer: User
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var subscriptions: [Subscription]
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedCategory: ProductCategory = .vegetables
    @State private var price = ""
    @State private var unit = "kg"
    @State private var minimumOrder = ""
    @State private var availableQuantity = ""
    @State private var isOrganic = false
    @State private var harvestDate = Date()
    @State private var expiryDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 1 week from now
    @State private var selectedDeliveryOptions: Set<DeliveryOption> = [.pickup]
    @State private var showingCategoryPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var userSubscription: Subscription? {
        subscriptions.first { $0.userID == farmer.id && $0.isActive }
    }
    
    private var currentProductCount: Int {
        // In a real app, you'd query the actual count
        return 3 // Placeholder
    }
    
    private var canAddProduct: Bool {
        guard let subscription = userSubscription else { return false }
        
        if subscription.plan == .free {
            return currentProductCount < (subscription.plan.maxListings ?? 0)
        }
        return true
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !description.isEmpty && !price.isEmpty && 
        !minimumOrder.isEmpty && !availableQuantity.isEmpty && !unit.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Product Information") {
                    TextField("Product Name", text: $name)
                    
                    Button(action: { showingCategoryPicker = true }) {
                        HStack {
                            Text("Category")
                            Spacer()
                            HStack {
                                Image(systemName: selectedCategory.icon)
                                    .foregroundColor(.green)
                                Text(selectedCategory.displayName)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Toggle("Organic Certified", isOn: $isOrganic)
                }
                
                Section("Pricing & Quantity") {
                    HStack {
                        TextField("Price", text: $price)
                            .keyboardType(.decimalPad)
                        Text("per")
                        TextField("Unit (kg, pieces, etc.)", text: $unit)
                    }
                    
                    TextField("Minimum Order", text: $minimumOrder)
                        .keyboardType(.decimalPad)
                    
                    TextField("Available Quantity", text: $availableQuantity)
                        .keyboardType(.decimalPad)
                }
                
                Section("Dates") {
                    DatePicker("Harvest Date", selection: $harvestDate, displayedComponents: .date)
                    DatePicker("Best Before", selection: $expiryDate, displayedComponents: .date)
                }
                
                Section("Delivery Options") {
                    ForEach(DeliveryOption.allCases, id: \.self) { option in
                        HStack {
                            Image(systemName: option.icon)
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text(option.displayName)
                            
                            Spacer()
                            
                            if selectedDeliveryOptions.contains(option) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedDeliveryOptions.contains(option) {
                                selectedDeliveryOptions.remove(option)
                            } else {
                                selectedDeliveryOptions.insert(option)
                            }
                        }
                    }
                }
                
                if !canAddProduct {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Upgrade Required")
                                .font(.headline)
                                .foregroundColor(.orange)
                            
                            Text("You've reached the limit for free listings. Upgrade to Pro to add unlimited products.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Upgrade Now") {
                                // Handle upgrade
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProduct()
                    }
                    .disabled(!isFormValid || !canAddProduct)
                }
            }
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerView(selectedCategory: $selectedCategory)
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveProduct() {
        guard let priceValue = Double(price),
              let minOrderValue = Double(minimumOrder),
              let quantityValue = Double(availableQuantity) else {
            alertMessage = "Please enter valid numbers for price and quantities."
            showingAlert = true
            return
        }
        
        let product = Product(
            name: name,
            description: description,
            category: selectedCategory,
            price: priceValue,
            unit: unit,
            farmerID: farmer.id,
            location: farmer.location
        )
        
        product.minimumOrder = minOrderValue
        product.availableQuantity = quantityValue
        product.isOrganic = isOrganic
        product.harvestDate = harvestDate
        product.expiryDate = expiryDate
        product.deliveryOptions = Array(selectedDeliveryOptions)
        product.latitude = farmer.latitude
        product.longitude = farmer.longitude
        
        modelContext.insert(product)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = "Failed to save product. Please try again."
            showingAlert = true
        }
    }
}

struct CategoryPickerView: View {
    @Binding var selectedCategory: ProductCategory
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(ProductCategory.allCases, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(.green)
                            .frame(width: 30)
                        
                        Text(category.displayName)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedCategory == category {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Select Category")
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

#Preview {
    let farmer = User(name: "Test Farmer", email: "farmer@test.com", phone: "123456789", userType: .farmer, location: "Orhei")
    
    return AddProductView(farmer: farmer)
        .modelContainer(for: [Product.self, Subscription.self], inMemory: true)
}
