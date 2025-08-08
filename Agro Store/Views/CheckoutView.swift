//
//  CheckoutView.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/8/25.
//

import SwiftUI
import PassKit

struct PaymentButtonView: UIViewRepresentable {
    let buttonType: PKPaymentButtonType
    let buttonStyle: PKPaymentButtonStyle
    let action: () -> Void
    
    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: buttonType, paymentButtonStyle: buttonStyle)
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: PKPaymentButton, context: Context) {
        // Nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        let action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func buttonTapped() {
            action()
        }
    }
}

struct CheckoutView: UIViewControllerRepresentable {
    typealias UIViewControllerType = PKPaymentAuthorizationViewController
    
    let product: Product
    let quantity: Double
    let deliveryOption: DeliveryOption
    let currentUser: User
    let onOrderCreated: (Order) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> PKPaymentAuthorizationViewController {
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.yourdomain.agrostore" // Replace with your merchant ID
        request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        request.merchantCapabilities = .threeDSecure
        request.countryCode = "US" // Replace with your country code
        request.currencyCode = "USD" // Replace with your currency code
        
        let totalAmount = NSDecimalNumber(value: product.price * quantity)
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: product.name, amount: totalAmount),
            PKPaymentSummaryItem(label: "Total", amount: totalAmount)
        ]
        
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
        let parent: CheckoutView
        
        init(_ parent: CheckoutView) {
            self.parent = parent
        }
        
        func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
            // Here you would send the payment token to your server or payment processor
            
            // Create the order when payment is successful
            let orderItem = OrderItem(
                productID: parent.product.id,
                productName: parent.product.name,
                quantity: parent.quantity,
                unitPrice: parent.product.price
            )
            
            let order = Order(
                customerID: parent.currentUser.id,
                farmerID: parent.product.farmerID,
                items: [orderItem],
                totalAmount: parent.product.price * parent.quantity,
                deliveryOption: parent.deliveryOption
            )
            
            // Mark payment as successful
            order.paymentStatus = .paid
            
            // Notify parent that order was created
            parent.onOrderCreated(order)
            
            // For demo, assume success
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
        }
        
        func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
            controller.dismiss(animated: true)
        }
    }
}

struct CheckoutViewWrapper: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext
    let product: Product
    let quantity: Double
    let deliveryOption: DeliveryOption
    let currentUser: User
    
    @State private var showApplePay = false
    @State private var orderCreated = false
    @State private var createdOrder: Order?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Checkout")
                .font(.largeTitle)
                .padding()
            
            Text("Product: \(product.name)")
            Text("Quantity: \(Int(quantity)) \(product.unit)")
            Text("Total: $\(String(format: "%.2f", product.price * quantity))")
            
            if orderCreated {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 60))
                    
                    Text("Order Placed Successfully!")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Order ID: \(createdOrder?.id.uuidString.prefix(8) ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("View Orders") {
                        presentationMode.wrappedValue.dismiss()
                        // Navigate to orders view would go here
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
                .padding()
            } else {
                PaymentButtonView(buttonType: .buy, buttonStyle: .black) {
                    showApplePay = true
                }
                .frame(height: 44)
                .cornerRadius(8)
                .padding()
                .sheet(isPresented: $showApplePay) {
                    CheckoutView(
                        product: product,
                        quantity: quantity,
                        deliveryOption: deliveryOption,
                        currentUser: currentUser
                    ) { order in
                        // Handle order creation
                        modelContext.insert(order)
                        try? modelContext.save()
                        createdOrder = order
                        orderCreated = true
                        showApplePay = false
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationBarTitle("Checkout", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

#Preview {
    let user = User(name: "Test User", email: "test@example.com", phone: "123456789", userType: .consumer, location: "Chisinau")
    let farmer = User(name: "Test Farmer", email: "farmer@test.com", phone: "987654321", userType: .farmer, location: "Orhei")
    farmer.farmName = "Green Valley Farm"
    farmer.isVerified = true
    farmer.rating = 4.8
    farmer.totalReviews = 47
    
    let product = Product(name: "Organic Tomatoes", description: "Fresh, locally grown organic tomatoes.", category: .vegetables, price: 15.0, unit: "kg", farmerID: farmer.id, farmerName: "Maria's Organic Farm", location: "Orhei")
    product.isOrganic = true
    product.availableQuantity = 50
    product.minimumOrder = 2
    product.deliveryOptions = [.pickup, .delivery]
    product.harvestDate = Date()
    
    return NavigationView {
        CheckoutViewWrapper(product: product, quantity: 3, deliveryOption: .pickup, currentUser: user)
    }
    .modelContainer(for: [Product.self, User.self, Order.self], inMemory: true)
}
