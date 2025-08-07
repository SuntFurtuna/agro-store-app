//
//  RegistrationView.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import SwiftUI
import SwiftData

struct RegistrationView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var currentUser: User?
    @Binding var showingOnboarding: Bool
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var selectedUserType: UserType = .consumer
    @State private var location = ""
    @State private var farmName = ""
    @State private var farmDescription = ""
    @State private var showingUserTypeSelection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Join AgroConnect")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Create your account to start connecting")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Account Type")
                                .font(.headline)
                            
                            Button(action: { showingUserTypeSelection = true }) {
                                HStack {
                                    Image(systemName: selectedUserType.icon)
                                        .foregroundColor(.green)
                                    Text(selectedUserType.displayName)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .foregroundColor(.primary)
                        }
                        
                        CustomTextField(title: "Full Name", text: $name, icon: "person.fill")
                        CustomTextField(title: "Email", text: $email, icon: "envelope.fill")
                        CustomTextField(title: "Phone", text: $phone, icon: "phone.fill")
                        CustomTextField(title: "Location (City/Region)", text: $location, icon: "location.fill")
                        
                        // Farm-specific fields
                        if selectedUserType == .farmer {
                            CustomTextField(title: "Farm Name", text: $farmName, icon: "leaf.fill")
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Farm Description")
                                    .font(.headline)
                                
                                TextField("Tell us about your farm...", text: $farmDescription, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3...6)
                            }
                        }
                    }
                    
                    // Register Button
                    Button(action: register) {
                        Text("Create Account")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.green : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!isFormValid)
                    
                    // Terms
                    Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingUserTypeSelection) {
            UserTypeSelectionView(selectedUserType: $selectedUserType)
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !phone.isEmpty && !location.isEmpty &&
        (selectedUserType != .farmer || !farmName.isEmpty)
    }
    
    private func register() {
        let user = User(name: name, email: email, phone: phone, userType: selectedUserType, location: location)
        
        if selectedUserType == .farmer {
            user.farmName = farmName
            user.farmDescription = farmDescription.isEmpty ? nil : farmDescription
        }
        
        modelContext.insert(user)
        
        // Create free subscription for the user
        let subscription = Subscription(userID: user.id, plan: .free)
        modelContext.insert(subscription)
        
        try? modelContext.save()
        
        currentUser = user
        showingOnboarding = false
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.green)
                    .frame(width: 20)
                
                TextField(title, text: $text)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct UserTypeSelectionView: View {
    @Binding var selectedUserType: UserType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(UserType.allCases, id: \.self) { userType in
                Button(action: {
                    selectedUserType = userType
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: userType.icon)
                            .foregroundColor(.green)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userType.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(userTypeDescription(userType))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedUserType == userType {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Select Account Type")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func userTypeDescription(_ userType: UserType) -> String {
        switch userType {
        case .farmer:
            return "Sell your farm products directly to consumers"
        case .consumer:
            return "Buy fresh produce directly from local farms"
        case .retailer:
            return "Source products for your store or business"
        case .restaurant:
            return "Find fresh ingredients for your restaurant"
        }
    }
}

#Preview {
    RegistrationView(currentUser: .constant(nil), showingOnboarding: .constant(true))
        .modelContainer(for: [User.self, Subscription.self], inMemory: true)
}
