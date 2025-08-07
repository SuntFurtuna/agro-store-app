//
//  SubscriptionManagementView.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import SwiftUI
import SwiftData

struct SubscriptionManagementView: View {
    let currentUser: User
    let currentSubscription: Subscription?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: SubscriptionPlan = .basic
    @State private var showingPayment = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("Upgrade Your Plan")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Unlock premium features and grow your business")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Current plan
                    if let subscription = currentSubscription {
                        CurrentPlanCard(subscription: subscription)
                    }
                    
                    // Available plans
                    VStack(spacing: 16) {
                        Text("Choose Your Plan")
                            .font(.headline)
                        
                        ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                            if plan != .free {
                                PlanCard(
                                    plan: plan,
                                    isSelected: selectedPlan == plan,
                                    isCurrentPlan: currentSubscription?.plan == plan,
                                    onSelect: { selectedPlan = plan }
                                )
                            }
                        }
                    }
                    
                    // Upgrade button
                    if currentSubscription?.plan != selectedPlan {
                        Button(action: { showingPayment = true }) {
                            Text(currentSubscription?.plan == .free ? "Start Free Trial" : "Upgrade Now")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Benefits comparison
                    BenefitsComparisonView()
                }
                .padding()
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPayment) {
            PaymentView(plan: selectedPlan, user: currentUser, onSuccess: {
                upgradeSubscription()
                dismiss()
            })
        }
    }
    
    private func upgradeSubscription() {
        // Deactivate current subscription
        if let current = currentSubscription {
            current.isActive = false
        }
        
        // Create new subscription
        let newSubscription = Subscription(userID: currentUser.id, plan: selectedPlan)
        modelContext.insert(newSubscription)
        
        // Update user pro status
        currentUser.isProSubscriber = selectedPlan != .free
        
        try? modelContext.save()
    }
}

struct CurrentPlanCard: View {
    let subscription: Subscription
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Plan")
                    .font(.headline)
                Spacer()
                Text("Active")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.plan.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if subscription.plan != .free {
                        Text("$\(subscription.plan.price, specifier: "%.2f")/month")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                Image(systemName: subscription.plan == .free ? "star" : "star.fill")
                    .font(.system(size: 30))
                    .foregroundColor(subscription.plan == .free ? .gray : .yellow)
            }
            
            if subscription.plan != .free {
                Text("Renews on \(subscription.endDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let isCurrentPlan: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("$\(plan.price, specifier: "%.2f")/month")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    if isCurrentPlan {
                        Text("Current")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    } else if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                    }
                }
                
                // Features
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(plan.features, id: \.self) { feature in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                                .font(.caption)
                                .padding(.top, 2)
                            
                            Text(feature)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                
                if plan == .premium {
                    Text("Most Popular")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
        }
        .disabled(isCurrentPlan)
    }
}

struct BenefitsComparisonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why upgrade?")
                .font(.headline)
            
            VStack(spacing: 12) {
                BenefitRow(
                    title: "Unlimited Listings",
                    description: "List as many products as you want",
                    icon: "infinity"
                )
                
                BenefitRow(
                    title: "Analytics Dashboard",
                    description: "Track sales, views, and customer insights",
                    icon: "chart.bar.fill"
                )
                
                BenefitRow(
                    title: "Featured Listings",
                    description: "Get priority placement in search results",
                    icon: "star.fill"
                )
                
                BenefitRow(
                    title: "Lower Commission",
                    description: "Keep more of your hard-earned money",
                    icon: "percent"
                )
                
                BenefitRow(
                    title: "Priority Support",
                    description: "Get help when you need it most",
                    icon: "headphones"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BenefitRow: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct PaymentView: View {
    let plan: SubscriptionPlan
    let user: User
    let onSuccess: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Summary
                VStack(spacing: 16) {
                    Text("Confirm Subscription")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 8) {
                        Text(plan.displayName)
                            .font(.headline)
                        
                        Text("$\(plan.price, specifier: "%.2f")/month")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text("Billed monthly • Cancel anytime")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Payment method (simplified)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Payment Method")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.blue)
                        Text("•••• •••• •••• 1234")
                        Spacer()
                        Text("VISA")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Confirm button
                Button(action: processPayment) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isProcessing ? "Processing..." : "Confirm & Subscribe")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isProcessing ? Color.gray : Color.green)
                    .cornerRadius(12)
                }
                .disabled(isProcessing)
            }
            .padding()
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isProcessing)
                }
            }
        }
    }
    
    private func processPayment() {
        isProcessing = true
        
        // Simulate payment processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false
            onSuccess()
        }
    }
}

#Preview {
    let user = User(name: "Test Farmer", email: "test@farm.com", phone: "123456789", userType: .farmer, location: "Chisinau")
    let subscription = Subscription(userID: user.id, plan: .free)
    
    return SubscriptionManagementView(currentUser: user, currentSubscription: subscription)
        .modelContainer(for: [Subscription.self], inMemory: true)
}
