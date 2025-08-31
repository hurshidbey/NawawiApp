//
//  NawawiApp.swift
//  Nawawi
//
//  Created by Khurshid Marazikov on 8/31/25.
//

import SwiftUI
import UserNotifications
import Combine

@main
struct NawawiApp: App {
    @StateObject private var appState = AppState()
    @State private var isAppActive = true
    
    init() {
        setupNotifications()
    }
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
                .onAppear {
                    appState.loadData()
                }
        } label: {
            // Custom menu bar icon with lantern-inspired design
            if let nsImage = NSImage(named: "AppIcon") {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .opacity(appState.hasActiveReminder ? 1.0 : 0.8)
            } else {
                // Fallback to SF Symbol if custom icon not found
                Image(systemName: appState.hasActiveReminder ? "lamp.ceiling.fill" : "lamp.ceiling")
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .menuBarExtraStyle(.window)
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
}

// MARK: - App State Management
class AppState: ObservableObject {
    @Published var currentHadithIndex = 0
    @Published var favorites: Set<Int> = []
    @Published var showSettings = false
    @Published var hasActiveReminder = false
    @Published var reminderInterval: TimeInterval = 3600 // 1 hour default
    @Published var lastViewedDate = Date()
    
    @AppStorage("favorites") private var favoritesData = Data()
    @AppStorage("lastHadithIndex") private var savedIndex = 0
    @AppStorage("reminderEnabled") var reminderEnabled = false
    @AppStorage("reminderHour") var reminderHour = 9
    @AppStorage("reminderMinute") var reminderMinute = 0
    
    private var reminderTimer: Timer?
    
    func loadData() {
        currentHadithIndex = savedIndex
        loadFavorites()
        if reminderEnabled {
            scheduleReminder()
        }
    }
    
    func saveCurrentIndex() {
        savedIndex = currentHadithIndex
    }
    
    func toggleFavorite(_ number: Int) {
        if favorites.contains(number) {
            favorites.remove(number)
        } else {
            favorites.insert(number)
        }
        saveFavorites()
    }
    
    private func loadFavorites() {
        if let decoded = try? JSONDecoder().decode(Set<Int>.self, from: favoritesData) {
            favorites = decoded
        }
    }
    
    func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            favoritesData = encoded
        }
    }
    
    func scheduleReminder() {
        reminderTimer?.invalidate()
        
        guard reminderEnabled else {
            hasActiveReminder = false
            return
        }
        
        hasActiveReminder = true
        
        // Schedule daily notification
        let content = UNMutableNotificationContent()
        content.title = "Daily Hadith Reminder"
        content.body = "Time to read today's hadith"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-hadith", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelReminder() {
        reminderTimer?.invalidate()
        hasActiveReminder = false
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-hadith"])
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.alert, .sound, .badge]
    }
}