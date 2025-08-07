//
//  CheckoutView.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/8/25.
//

import SwiftUI
import PassKit

import PassKit
import SwiftUI

struct CheckoutView: UIViewControllerRepresentable {
    typealias UIViewControllerType = PKPaymentAuthorizationViewController
    
    let product: Product
    let quantity: Double
    let deliveryOption: DeliveryOption
    let currentUser: User
    
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
    let product: Product
    let quantity: Double
    let deliveryOption: DeliveryOption
    let currentUser: User
    
    @State private var showApplePay = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Checkout")
                .font(.largeTitle)
                .padding()
            
            Text("Product: \(product.name)")
            Text("Quantity: \(Int(quantity)) \(product.unit)")
            Text("Total: $\(String(format: "%.2f", product.price * quantity))")
            
            Button(action: {
                showApplePay = true
            }) {
                PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
                    .frame(height: 44)
                    .background(Color.black)
                    .cornerRadius(8)
            }
            .padding()
            .sheet(isPresented: $showApplePay) {
                CheckoutView(product: product, quantity: quantity, deliveryOption: deliveryOption, currentUser: currentUser)
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
    
    let product = Product(name: "Organic Tomatoes", description: "Fresh, locally grown organic tomatoes.", category: .vegetables, price: 15.0, unit: "kg", farmerID: farmer.id, location: "Orhei")
    product.isOrganic = true
    product.availableQuantity = 50
    product.minimumOrder = 2
    product.deliveryOptions = [.pickup, .delivery]
    product.harvestDate = Date()
    
    return NavigationView {
        CheckoutViewWrapper(product: product, quantity: 3, deliveryOption: .pickup, currentUser: user)
    }
    .modelContainer(for: [Product.self, User.self], inMemory: true)
}
