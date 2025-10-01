//
//  NawawiApp.swift
//  Nawawi
//
//  Created by Khurshid Marazikov on 8/31/25.
//

import SwiftUI
import UserNotifications
import Combine
import ServiceManagement

@main
struct NawawiApp: App {
    @StateObject private var appState = AppState()
    @State private var isAppActive = true

    init() {
        setupNotifications()
    }

    var body: some Scene {
        // Onboarding window (shown on first launch)
        WindowGroup("Welcome", id: "onboarding") {
            OnboardingView {
                appState.completeOnboarding()
            }
            .environmentObject(appState)
            .colorScheme(.light)
            .onAppear {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .defaultSize(width: 600, height: 550)
        .defaultPosition(.center)
        .windowResizability(.contentSize)

        // Main standalone window
        WindowGroup("40 Hadith Nawawi", id: "main-window") {
            MainWindowView()
                .environmentObject(appState)
                .colorScheme(.light) // Force light mode globally
                .foregroundColor(.black) // Force all text to be black
                .onAppear {
                    appState.loadData()
                    // Activate app for macOS 26 Tahoe visibility
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .defaultSize(width: 1100, height: 750)
        .defaultPosition(.center)

        // Menu bar extra for quick access
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
                .colorScheme(.light) // Force light mode globally
                .foregroundColor(.black) // Force all text to be black
                .task {
                    // Set activation policy to allow windows to open
                    NSApp.setActivationPolicy(.regular)

                    // Load data when menu bar appears
                    appState.loadData()
                    print("🚀 MenuBarExtra task - showOnboarding: \(appState.showOnboarding)")
                }
                .onAppear {
                    // Activate app for macOS 26 Tahoe visibility
                    NSApp.activate(ignoringOtherApps: true)
                }
        } label: {
            Image(systemName: appState.hasActiveReminder ? "book.fill" : "book")
                .renderingMode(.template) // Critical for macOS 26 Tahoe
        }
        .menuBarExtraStyle(.window) // Use window style for richer UI
    }

    private func setupNotifications() {
        // Set the delegate first
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

        // Request authorization with completion handler
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                print("Notification permission granted: \(granted)")

                // Check current settings
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                print("Authorization status: \(settings.authorizationStatus.rawValue)")

                if settings.authorizationStatus == .notDetermined {
                    print("Permissions not determined - requesting again")
                    _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                }
            } catch {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
}

// MARK: - App State Management
enum AppLanguage: String, CaseIterable {
    case arabic = "ar"
    case english = "en"
    case uzbek = "uz"

    var displayName: String {
        switch self {
        case .arabic: return "العربية"
        case .english: return "English"
        case .uzbek: return "O'zbek"
        }
    }

    var flag: String {
        switch self {
        case .arabic: return "🇸🇦"
        case .english: return "🇬🇧"
        case .uzbek: return "🇺🇿"
        }
    }
}

class AppState: ObservableObject {
    @Published var currentHadithIndex = 0
    @Published var favorites: Set<Int> = []
    @Published var showSettings = false
    @Published var hasActiveReminder = false
    @Published var reminderInterval: TimeInterval = 3600 // 1 hour default
    @Published var lastViewedDate = Date()
    @Published var selectedLanguage: AppLanguage = .english {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: "selectedLanguage")
        }
    }
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
    @Published var shouldOpenMainWindow = false
    @Published var showOnboarding = false

    @AppStorage("favorites") private var favoritesData = Data()
    @AppStorage("lastHadithIndex") private var savedIndex = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("launchAtLogin") var launchAtLogin = false

    private var reminderTimer: Timer?

    func loadData() {
        currentHadithIndex = savedIndex
        loadFavorites()

        // Load language preference
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            selectedLanguage = language
        }

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

        // Check if onboarding should be shown
        showOnboarding = !hasCompletedOnboarding
        print("🚀 AppState.loadData() - hasCompletedOnboarding: \(hasCompletedOnboarding), showOnboarding: \(showOnboarding)")
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        showOnboarding = false
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

                    // Schedule daily notification with random hadith
                    let content = UNMutableNotificationContent()
                    content.title = "Daily Hadith Reminder"

                    // Select a random hadith number (1-40)
                    let randomHadithNumber = Int.random(in: 1...40)
                    content.body = "Time to read Hadith #\(randomHadithNumber)"
                    content.sound = .default
                    content.categoryIdentifier = "HADITH_REMINDER"
                    content.userInfo = ["hadithNumber": randomHadithNumber]

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

    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run {
                    completion(granted)
                }
            } catch {
                print("Permission request error: \(error)")
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }

    func checkNotificationPermission(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    func updateLaunchAtLogin() {
        #if os(macOS)
        do {
            let service = SMAppService.mainApp
            if launchAtLogin {
                if service.status == .enabled {
                    print("Launch at login already enabled")
                } else {
                    try service.register()
                    print("Launch at login enabled")
                }
            } else {
                if service.status == .enabled {
                    try service.unregister()
                    print("Launch at login disabled")
                }
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
        #endif
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.alert, .sound, .badge]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // Handle notification tap
        if let hadithNumber = response.notification.request.content.userInfo["hadithNumber"] as? Int {
            print("User tapped notification for Hadith #\(hadithNumber)")
            // Navigate to the specific hadith (index is number - 1)
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenHadith"),
                    object: nil,
                    userInfo: ["hadithIndex": hadithNumber - 1]
                )
            }
        }
    }
}
