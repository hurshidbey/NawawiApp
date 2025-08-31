//
//  NawawiApp.swift
//  Nawawi
//
//  Created by Khurshid Marazikov on 8/31/25.
//

import SwiftUI
import SwiftData

@main
struct NawawiApp: App {
    @StateObject private var hadithManager = HadithManager()
    @StateObject private var notificationManager = NotificationManager()
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    
    init() {
        // Setup relationship between managers after initialization
        _hadithManager = StateObject(wrappedValue: HadithManager())
        _notificationManager = StateObject(wrappedValue: NotificationManager())
    }
    
    var sharedModelContainer: ModelContainer {
        let schema = Schema([
            Hadith.self,
            Settings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Better error handling - log and create in-memory container as fallback
            print("Failed to create persistent ModelContainer: \(error)")
            print("Falling back to in-memory storage")
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallbackConfig])
        }
    }

    var body: some Scene {
        MenuBarExtra("Nawawi", systemImage: "book.fill") {
            MenuBarView()
                .environmentObject(hadithManager)
                .environmentObject(notificationManager)
                .modelContainer(sharedModelContainer)
                .onAppear {
                    // Connect managers after UI is ready
                    hadithManager.setNotificationManager(notificationManager)
                }
        }
        .menuBarExtraStyle(.window)
    }
}
