//
//  CartCheckoutView.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/8/25.
//

import SwiftUI
import SwiftData
import PassKit

struct CartCheckoutView: View {
    let cartItems: [CartItem]
    let currentUser: User
    let onOrderComplete: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var products: [Product]
    
    @State private var selectedDeliveryOption: DeliveryOption = .pickup
    @State private var deliveryAddress = ""
    @State private var orderNotes = ""
    @State private var showingApplePay = false
    @State private var orderCreated = false
    @State private var createdOrder: Order?
    
    private var totalAmount: Double {
        cartItems.reduce(0) { $0 + $1.totalPrice }
    }
    
    private var groupedByFarmer: [UUID: [CartItem]] {
        Dictionary(grouping: cartItems) { cartItem in
            products.first { $0.id == cartItem.productID }?.farmerID ?? UUID()
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if orderCreated {
                    // Success view
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 80))
                        
                        Text("Order Placed Successfully!")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if let order = createdOrder {
                            Text("Order ID: \(order.id.uuidString.prefix(8))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("You will receive confirmation from the farmers soon.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Continue Shopping") {
                            onOrderComplete()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Order summary
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Order Summary")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                ForEach(cartItems, id: \.id) { cartItem in
                                    HStack {
                                        Text(cartItem.productName)
                                        Spacer()
                                        Text("\(Int(cartItem.quantity)) \(cartItem.unit)")
                                            .foregroundColor(.secondary)
                                        Text("$\(String(format: "%.2f", cartItem.totalPrice))")
                                            .fontWeight(.medium)
                                    }
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Total")
                                        .font(.headline)
                                    Spacer()
                                    Text("$\(String(format: "%.2f", totalAmount))")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            // Delivery options
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Delivery Option")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                ForEach(DeliveryOption.allCases, id: \.self) { option in
                                    HStack {
                                        Button(action: {
                                            selectedDeliveryOption = option
                                        }) {
                                            HStack {
                                                Image(systemName: selectedDeliveryOption == option ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(selectedDeliveryOption == option ? .green : .gray)
                                                
                                                Image(systemName: option.icon)
                                                    .foregroundColor(.blue)
                                                
                                                Text(option.displayName)
                                                    .foregroundColor(.primary)
                                                
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                                
                                if selectedDeliveryOption == .delivery {
                                    TextField("Delivery address", text: $deliveryAddress)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            // Order notes
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Order Notes (Optional)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                TextField("Any special instructions?", text: $orderNotes, axis: .vertical)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .lineLimit(3)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            // Payment button
                            PaymentButtonView(buttonType: .buy, buttonStyle: .black) {
                                showingApplePay = true
                            }
                            .frame(height: 44)
                            .cornerRadius(8)
                            .padding()
                            .sheet(isPresented: $showingApplePay) {
                                CartApplePayView(
                                    cartItems: cartItems,
                                    totalAmount: totalAmount,
                                    deliveryOption: selectedDeliveryOption,
                                    currentUser: currentUser
                                ) { order in
                                    // Handle order creation
                                    modelContext.insert(order)
                                    try? modelContext.save()
                                    createdOrder = order
                                    orderCreated = true
                                    showingApplePay = false
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CartApplePayView: UIViewControllerRepresentable {
    typealias UIViewControllerType = PKPaymentAuthorizationViewController
    
    let cartItems: [CartItem]
    let totalAmount: Double
    let deliveryOption: DeliveryOption
    let currentUser: User
    let onOrderCreated: (Order) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> PKPaymentAuthorizationViewController {
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.yourdomain.agrostore"
        request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        request.merchantCapabilities = .threeDSecure
        request.countryCode = "US"
        request.currencyCode = "USD"
        
        // Create payment summary items
        var paymentItems: [PKPaymentSummaryItem] = []
        
        for cartItem in cartItems {
            let item = PKPaymentSummaryItem(
                label: "\(cartItem.productName) (\(Int(cartItem.quantity)) \(cartItem.unit))",
                amount: NSDecimalNumber(value: cartItem.totalPrice)
            )
            paymentItems.append(item)
        }
        
        // Add total
        paymentItems.append(PKPaymentSummaryItem(
            label: "Total",
            amount: NSDecimalNumber(value: totalAmount)
        ))
        
        request.paymentSummaryItems = paymentItems
        
        guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: request) else {
            fatalError("Unable to create PKPaymentAuthorizationViewController")
        }
        paymentVC.delegate = context.coordinator
        return paymentVC
    }
    
    func updateUIViewController(_ uiViewController: PKPaymentAuthorizationViewController, context: Context) {
        // No update needed
    }
    
    class Coordinator: NSObject, PKPaymentAuthorizationViewControllerDelegate {
        let parent: CartApplePayView
        
        init(_ parent: CartApplePayView) {
            self.parent = parent
        }
        
        func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
            // Create order items
            let orderItems = parent.cartItems.map { cartItem in
                OrderItem(
                    productID: cartItem.productID,
                    productName: cartItem.productName,
                    quantity: cartItem.quantity,
                    unitPrice: cartItem.productPrice
                )
            }
            
            // For simplicity, create one order with the first farmer ID
            // In a real app, you might want to split into multiple orders by farmer
            let firstProduct = parent.cartItems.compactMap { cartItem in
                // You'd need to fetch the product to get the farmer ID
                // For now, using a placeholder
                return UUID() // This should be the actual farmer ID from the product
            }.first ?? UUID()
            
            let order = Order(
                customerID: parent.currentUser.id,
                farmerID: firstProduct,
                items: orderItems,
                totalAmount: parent.totalAmount,
                deliveryOption: parent.deliveryOption
            )
            
            order.paymentStatus = .paid
            
            parent.onOrderCreated(order)
            
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
        }
        
        func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
            controller.dismiss(animated: true)
        }
    }
}

#Preview {
    let user = User(name: "Test User", email: "test@example.com", phone: "123456789", userType: .consumer, location: "Chisinau")
    
    let cartItem1 = CartItem(userID: user.id, productID: UUID(), productName: "Organic Tomatoes", productPrice: 25.0, quantity: 2, unit: "kg", deliveryOption: .pickup)
    let cartItem2 = CartItem(userID: user.id, productID: UUID(), productName: "Fresh Apples", productPrice: 20.0, quantity: 1, unit: "kg", deliveryOption: .pickup)
    
    return CartCheckoutView(cartItems: [cartItem1, cartItem2], currentUser: user, onOrderComplete: {})
        .modelContainer(for: [CartItem.self, Product.self, Order.self], inMemory: true)
}
