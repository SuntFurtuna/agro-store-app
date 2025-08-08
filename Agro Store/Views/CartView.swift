//
//  CartView.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/8/25.
//

import SwiftUI
import SwiftData

struct CartView: View {
    let currentUser: User
    @Environment(\.modelContext) private var modelContext
    @Query private var allCartItems: [CartItem]
    @Query private var products: [Product]
    
    private var userCartItems: [CartItem] {
        allCartItems.filter { $0.userID == currentUser.id }
    }
    
    private var totalAmount: Double {
        userCartItems.reduce(0) { $0 + $1.totalPrice }
    }
    
    @State private var showingCheckout = false
    
    var body: some View {
        NavigationView {
            VStack {
                if userCartItems.isEmpty {
                    // Empty cart state
                    VStack(spacing: 20) {
                        Image(systemName: "cart")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("Your cart is empty")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Add some products to get started")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Cart items list
                    List {
                        ForEach(userCartItems, id: \.id) { cartItem in
                            CartItemRow(
                                cartItem: cartItem,
                                product: products.first { $0.id == cartItem.productID },
                                onQuantityChange: { newQuantity in
                                    updateQuantity(for: cartItem, newQuantity: newQuantity)
                                },
                                onRemove: {
                                    removeItem(cartItem)
                                }
                            )
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(PlainListStyle())
                    
                    // Checkout section
                    VStack(spacing: 16) {
                        Divider()
                        
                        HStack {
                            Text("Total:")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.2f", totalAmount))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            showingCheckout = true
                        }) {
                            Text("Proceed to Checkout")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .disabled(userCartItems.isEmpty)
                    }
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("Cart")
            .sheet(isPresented: $showingCheckout) {
                CartCheckoutView(cartItems: userCartItems, currentUser: currentUser) {
                    // Clear cart after successful checkout
                    clearCart()
                }
            }
        }
    }
    
    private func updateQuantity(for cartItem: CartItem, newQuantity: Double) {
        cartItem.quantity = newQuantity
        try? modelContext.save()
    }
    
    private func removeItem(_ cartItem: CartItem) {
        modelContext.delete(cartItem)
        try? modelContext.save()
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let cartItem = userCartItems[index]
            modelContext.delete(cartItem)
        }
        try? modelContext.save()
    }
    
    private func clearCart() {
        for cartItem in userCartItems {
            modelContext.delete(cartItem)
        }
        try? modelContext.save()
    }
}

struct CartItemRow: View {
    let cartItem: CartItem
    let product: Product?
    let onQuantityChange: (Double) -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Product image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: product?.category.icon ?? "leaf.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(cartItem.productName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("$\(String(format: "%.2f", cartItem.productPrice))/\(cartItem.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(cartItem.deliveryOption.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                // Quantity controls
                HStack(spacing: 8) {
                    Button(action: {
                        if cartItem.quantity > 1 {
                            onQuantityChange(cartItem.quantity - 1)
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(cartItem.quantity > 1 ? .red : .gray)
                    }
                    .disabled(cartItem.quantity <= 1)
                    
                    Text("\(Int(cartItem.quantity))")
                        .font(.headline)
                        .frame(minWidth: 30)
                    
                    Button(action: {
                        if let maxQuantity = product?.availableQuantity, cartItem.quantity < maxQuantity {
                            onQuantityChange(cartItem.quantity + 1)
                        } else if product?.availableQuantity == nil {
                            onQuantityChange(cartItem.quantity + 1)
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                Text("$\(String(format: "%.2f", cartItem.totalPrice))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Remove", action: onRemove)
                .tint(.red)
        }
    }
}

#Preview {
    let user = User(name: "Test User", email: "test@example.com", phone: "123456789", userType: .consumer, location: "Chisinau")
    
    return CartView(currentUser: user)
        .modelContainer(for: [CartItem.self, Product.self], inMemory: true)
}
