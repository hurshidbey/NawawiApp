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
            // Use simple book icon for menu bar - custom icons don't scale well here
            Image(systemName: appState.hasActiveReminder ? "book.fill" : "book")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // Check and print current notification settings for debugging
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings.authorizationStatus.rawValue)")
        }
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
    @Published var reminderEnabled = false {
        didSet {
            UserDefaults.standard.set(reminderEnabled, forKey: "reminderEnabled")
        }
    }
    @Published var reminderHour = 9 {
        didSet {
            UserDefaults.standard.set(reminderHour, forKey: "reminderHour")
        }
    }
    @Published var reminderMinute = 0 {
        didSet {
            UserDefaults.standard.set(reminderMinute, forKey: "reminderMinute")
        }
    }
    
    @AppStorage("favorites") private var favoritesData = Data()
    @AppStorage("lastHadithIndex") private var savedIndex = 0
    
    private var reminderTimer: Timer?
    
    func loadData() {
        currentHadithIndex = savedIndex
        loadFavorites()
        
        // Load reminder settings from UserDefaults
        reminderEnabled = UserDefaults.standard.bool(forKey: "reminderEnabled")
        reminderHour = UserDefaults.standard.integer(forKey: "reminderHour")
        reminderMinute = UserDefaults.standard.integer(forKey: "reminderMinute")
        
        // Set defaults if not set
        if reminderHour == 0 && reminderMinute == 0 {
            reminderHour = 9
            reminderMinute = 0
        }
        
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
        
        // First check notification permissions
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if settings.authorizationStatus == .authorized {
                    self.hasActiveReminder = true
                    
                    // Remove existing notifications
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-hadith"])
                    
                    // Schedule daily notification
                    let content = UNMutableNotificationContent()
                    content.title = "Daily Hadith Reminder"
                    content.body = "Time to read today's hadith"
                    content.sound = .default
                    content.categoryIdentifier = "HADITH_REMINDER"
                    
                    var dateComponents = DateComponents()
                    dateComponents.hour = self.reminderHour
                    dateComponents.minute = self.reminderMinute
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                    let request = UNNotificationRequest(identifier: "daily-hadith", content: content, trigger: trigger)
                    
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("Error scheduling notification: \(error)")
                            DispatchQueue.main.async {
                                self.hasActiveReminder = false
                                self.reminderEnabled = false
                            }
                        } else {
                            print("Notification scheduled for \(self.reminderHour):\(String(format: "%02d", self.reminderMinute))")
                        }
                    }
                } else {
                    // No permission, disable reminders
                    self.reminderEnabled = false
                    self.hasActiveReminder = false
                    print("Notification permission not granted")
                    
                    // Request permission again
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                        if granted {
                            DispatchQueue.main.async {
                                self.scheduleReminder()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func cancelReminder() {
        reminderTimer?.invalidate()
        hasActiveReminder = false
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-hadith"])
    }
    
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Reminder"
        content.body = "Your daily hadith reminders are working!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Test notification error: \(error)")
            } else {
                print("Test notification scheduled - will appear in 5 seconds")
            }
        }
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.alert, .sound, .badge]
    }
}