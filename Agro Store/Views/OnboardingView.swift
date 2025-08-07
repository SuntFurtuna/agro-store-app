//
//  OnboardingView.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var currentUser: User?
    @Binding var showingOnboarding: Bool
    
    @State private var currentPage = 0
    @State private var showingRegistration = false
    
    let onboardingPages = [
        OnboardingPage(
            title: "Welcome to AgroConnect",
            subtitle: "Moldova's Farm-to-Market Platform",
            description: "Connect directly with local farmers and get the freshest produce delivered to your door",
            imageName: "leaf.fill",
            color: .green
        ),
        OnboardingPage(
            title: "For Farmers",
            subtitle: "Grow Your Business",
            description: "List your products, reach more customers, and get fair prices for your hard work",
            imageName: "person.crop.circle.fill",
            color: .blue
        ),
        OnboardingPage(
            title: "For Consumers",
            subtitle: "Fresh & Local",
            description: "Discover local produce, support your community, and enjoy farm-fresh quality",
            imageName: "cart.fill",
            color: .orange
        ),
        OnboardingPage(
            title: "Smart Marketplace",
            subtitle: "Find What You Need",
            description: "Use our map to find nearby farmers, browse by category, or post what you're looking for",
            imageName: "map.fill",
            color: .purple
        )
    ]
    
    var body: some View {
        if showingRegistration {
            RegistrationView(currentUser: $currentUser, showingOnboarding: $showingOnboarding)
        } else {
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        OnboardingPageView(page: onboardingPages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                VStack(spacing: 16) {
                    Button(action: {
                        if currentPage < onboardingPages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            showingRegistration = true
                        }
                    }) {
                        Text(currentPage < onboardingPages.count - 1 ? "Next" : "Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundColor(page.color)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(page.color)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView(currentUser: .constant(nil), showingOnboarding: .constant(true))
        .modelContainer(for: [User.self], inMemory: true)
}
