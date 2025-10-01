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
// Sparkle will be added via Swift Package Manager - uncomment after adding package:
// import Sparkle

@main
struct NawawiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @State private var isAppActive = true

    // Sparkle updater controller - uncomment after adding Sparkle package:
    // private let updaterController: SPUStandardUpdaterController

    init() {
        setupNotifications()

        // Initialize Sparkle - uncomment after adding package:
        // updaterController = SPUStandardUpdaterController(
        //     startingUpdater: true,
        //     updaterDelegate: nil,
        //     userDriverDelegate: nil
        // )
    }

    private func setupNotificationsWithState() {
        NotificationDelegate.shared.appState = appState
    }

    var body: some Scene {
        // Onboarding window (shown on first launch)
        WindowGroup("Welcome", id: "onboarding") {
            OnboardingView {
                appState.completeOnboarding()
            }
            .environmentObject(appState)
            .colorScheme(.light)
            .task {
                // Ensure activation policy allows windows
                NSApp.setActivationPolicy(.regular)
            }
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
                .task {
                    // Ensure activation policy allows windows
                    NSApp.setActivationPolicy(.regular)
                    appState.loadData()
                }
                .onAppear {
                    // Activate app for macOS 26 Tahoe visibility
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .defaultSize(width: 1100, height: 750)
        .defaultPosition(.center)
        .handlesExternalEvents(matching: ["main-window"])

        // Menu bar extra for quick access
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
                .colorScheme(.light) // Force light mode globally
                .foregroundColor(.black) // Force all text to be black
                .task {
                    // Set activation policy to allow windows to open
                    NSApp.setActivationPolicy(.regular)

                    // Inject appState into NotificationDelegate
                    NotificationDelegate.shared.appState = appState

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

        // Register notification categories
        // Don't add any actions - just register the category
        // This prevents macOS from trying to launch the app
        let category = UNNotificationCategory(
            identifier: "HADITH_REMINDER",
            actions: [], // Empty actions array
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])

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
    @Published var pendingHadithNavigation: Int? = nil

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

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running in menu bar even when all windows are closed
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // This is a menu bar app - it should only quit explicitly
        return .terminateNow
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        print("🔄 App reopen requested - hasVisibleWindows: \(flag)")

        // Always ensure activation policy allows windows
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // If no windows visible, open main window
        if !flag {
            print("📂 Opening main window (no visible windows)")

            // Use a small delay to ensure app is fully activated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: NSNotification.Name("OpenMainWindow"), object: nil)

                // Double-check window appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if let window = NSApp.windows.first(where: { $0.title == "40 Hadith Nawawi" }) {
                        window.makeKeyAndOrderFront(nil)
                        print("✅ Main window opened and brought to front")
                    } else {
                        print("⚠️ Failed to find main window after reopen")
                    }
                }
            }
        } else {
            // Windows exist, just bring the main one to front
            if let window = NSApp.windows.first(where: { $0.title == "40 Hadith Nawawi" }) {
                window.makeKeyAndOrderFront(nil)
                print("✅ Brought existing main window to front")
            }
        }

        return true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy to regular to allow windows
        NSApp.setActivationPolicy(.regular)
        print("✅ App finished launching - activation policy set to .regular")
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // Ensure activation policy is correct whenever app becomes active
        print("✅ App became active")
        NSApp.setActivationPolicy(.regular)
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    weak var appState: AppState?

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let actionIdentifier = response.actionIdentifier
        print("🔔 Notification clicked: \(actionIdentifier)")

        // Handle notification tap (default action)
        guard actionIdentifier == UNNotificationDefaultActionIdentifier else {
            print("⚠️ Unknown action identifier: \(actionIdentifier)")
            return
        }

        guard let hadithNumber = response.notification.request.content.userInfo["hadithNumber"] as? Int else {
            print("⚠️ No hadith number in notification")
            return
        }

        print("🔔 Opening Hadith #\(hadithNumber)")

        // CRITICAL: Use MainActor for all UI operations
        await MainActor.run {
            // 1. Set activation policy and activate app
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)

            // 2. Store the hadith index in AppState FIRST
            if let appState = self.appState {
                appState.currentHadithIndex = hadithNumber - 1
                appState.pendingHadithNavigation = hadithNumber - 1
                appState.shouldOpenMainWindow = true  // Signal to open window
                print("✅ Set hadith index and shouldOpenMainWindow flag")
            }

            // 3. Open or bring forward window
            self.openMainWindow(forHadith: hadithNumber - 1)
        }
    }

    /// Opens the main window using proper AppKit APIs
    private func openMainWindow(forHadith index: Int) {
        // Try to find existing main window first
        if let existingWindow = NSApp.windows.first(where: { $0.title == "40 Hadith Nawawi" || $0.identifier?.rawValue.contains("main-window") == true }) {
            print("✅ Found existing main window, bringing to front")
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)

            // Post navigation event after window is visible
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenHadith"),
                    object: nil,
                    userInfo: ["hadithIndex": index]
                )
                print("✅ Posted navigation to hadith \(index)")
            }
        } else {
            print("✅ No existing window found, creating new window")

            // CRITICAL: For SwiftUI WindowGroup, we must trigger window creation properly
            // Post notification first to trigger SwiftUI's window system
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenMainWindow"),
                object: nil,
                userInfo: ["hadithIndex": index]
            )

            // Use performSelector to execute on next run loop - gives SwiftUI time to process
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Check if window was created
                if let newWindow = NSApp.windows.first(where: { $0.title == "40 Hadith Nawawi" || $0.identifier?.rawValue.contains("main-window") == true }) {
                    newWindow.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                    print("✅ Window created and activated")

                    // Navigate to hadith
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("OpenHadith"),
                            object: nil,
                            userInfo: ["hadithIndex": index]
                        )
                        print("✅ Navigated to hadith \(index)")
                    }
                } else {
                    // SwiftUI window creation failed, try using AppDelegate method
                    print("⚠️ SwiftUI window creation failed, using AppDelegate fallback")
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        _ = appDelegate.applicationShouldHandleReopen(NSApp, hasVisibleWindows: false)

                        // Try again after delegation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if let finalWindow = NSApp.windows.first(where: { $0.title == "40 Hadith Nawawi" }) {
                                finalWindow.makeKeyAndOrderFront(nil)
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("OpenHadith"),
                                    object: nil,
                                    userInfo: ["hadithIndex": index]
                                )
                                print("✅ Window opened via AppDelegate fallback")
                            } else {
                                print("❌ Failed to create main window - all methods exhausted")
                            }
                        }
                    }
                }
            }
        }
    }
}
