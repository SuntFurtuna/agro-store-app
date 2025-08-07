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
        }
    }
    
    private func checkForExistingUser() {
        // In a real app, you'd check for stored user credentials
        // For now, we'll show onboarding
        showingOnboarding = true
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
        .modelContainer(for: [User.self, Product.self, Order.self, OrderItem.self, DemandRequest.self, RequestResponse.self, Subscription.self], inMemory: true)
}
