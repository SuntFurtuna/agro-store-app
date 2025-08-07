//
//  Agro_StoreApp.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import SwiftUI
import SwiftData

@main
struct Agro_StoreApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Product.self,
            Order.self,
            OrderItem.self,
            DemandRequest.self,
            RequestResponse.self,
            Subscription.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
