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
import Sparkle

@main
struct NawawiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Core managers following dependency injection pattern
    @StateObject private var hadithDataManager = HadithDataManager()
    @StateObject private var favoritesManager = FavoritesManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var appState = AppState()

    // Services (Phase 4: Deduplication)
    @StateObject private var hadithActionService = HadithActionService()
    @StateObject private var speechService = SpeechService()

    @State private var isAppActive = true

    init() {
        setupNotifications()
        // Sparkle initialization moved to AppDelegate.applicationDidFinishLaunching
        // to avoid race condition accessing appDelegate before initialization
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
            .environmentObject(notificationManager)
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
                .environmentObject(hadithDataManager)
                .environmentObject(favoritesManager)
                .environmentObject(notificationManager)
                .environmentObject(hadithActionService)
                .environmentObject(speechService)
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
                .environmentObject(hadithDataManager)
                .environmentObject(favoritesManager)
                .environmentObject(notificationManager)
                .environmentObject(hadithActionService)
                .environmentObject(speechService)
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
            Image(systemName: notificationManager.hasActiveReminder ? "book.fill" : "book")
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

@MainActor
class AppState: ObservableObject {
    // MARK: - Composed State Objects
    // Using composition pattern - each state object handles one responsibility
    let navigationState = NavigationState()
    let preferencesState = PreferencesState()
    let onboardingState = OnboardingState()

    // MARK: - UI-Only State (not persisted)
    @Published var showSettings = false

    // MARK: - Published Properties (synced with state objects)
    // These are @Published to support SwiftUI bindings ($property)
    private var cancellables = Set<AnyCancellable>()

    @Published var currentHadithIndex = 0
    @Published var selectedLanguage: AppLanguage = .english
    @Published var showOnboarding = false
    @Published var pendingHadithNavigation: Int? = nil
    @Published var shouldOpenMainWindow = false

    // Delegated to preferencesState (cannot be @Published due to @AppStorage)
    var launchAtLogin: Bool {
        get { preferencesState.launchAtLogin }
        set { preferencesState.launchAtLogin = newValue }
    }

    init() {
        // Sync state objects with published properties
        syncStateObjects()
    }

    private func syncStateObjects() {
        // Navigation state sync - one-way bindings to prevent circular updates
        navigationState.$currentHadithIndex
            .removeDuplicates()
            .sink { [weak self] value in
                guard let self = self, self.currentHadithIndex != value else { return }
                self.currentHadithIndex = value
            }
            .store(in: &cancellables)

        $currentHadithIndex
            .removeDuplicates()
            .sink { [weak self] value in
                guard let self = self, self.navigationState.currentHadithIndex != value else { return }
                self.navigationState.currentHadithIndex = value
            }
            .store(in: &cancellables)

        navigationState.$pendingHadithNavigation
            .sink { [weak self] value in
                guard let self = self, self.pendingHadithNavigation != value else { return }
                self.pendingHadithNavigation = value
            }
            .store(in: &cancellables)

        navigationState.$shouldOpenMainWindow
            .sink { [weak self] value in
                guard let self = self, self.shouldOpenMainWindow != value else { return }
                self.shouldOpenMainWindow = value
            }
            .store(in: &cancellables)

        // Preferences state sync
        preferencesState.$selectedLanguage
            .removeDuplicates()
            .sink { [weak self] value in
                guard let self = self, self.selectedLanguage != value else { return }
                self.selectedLanguage = value
            }
            .store(in: &cancellables)

        $selectedLanguage
            .removeDuplicates()
            .sink { [weak self] value in
                guard let self = self, self.preferencesState.selectedLanguage != value else { return }
                self.preferencesState.selectedLanguage = value
            }
            .store(in: &cancellables)

        // Onboarding state sync
        onboardingState.$showOnboarding
            .sink { [weak self] value in
                guard let self = self, self.showOnboarding != value else { return }
                self.showOnboarding = value
            }
            .store(in: &cancellables)
    }

    // MARK: - Lifecycle

    func loadData() {
        // All state objects auto-load in their init()
        // NOTE: Favorites managed by FavoritesManager
        // NOTE: Notifications managed by NotificationManager
        print("🚀 AppState.loadData() - delegating to state objects")
    }

    // MARK: - Convenience Methods (delegate to state objects)

    func completeOnboarding() {
        onboardingState.completeOnboarding()
    }

    func saveCurrentIndex() {
        navigationState.saveCurrentIndex()
    }

    func updateLaunchAtLogin() {
        preferencesState.updateLaunchAtLogin()
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var updaterController: SPUStandardUpdaterController!

    func setupSparkle() {
        // Initialize Sparkle updater
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        print("✅ Sparkle updater initialized")
    }

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

        // Initialize Sparkle auto-updater (moved here to avoid race condition)
        setupSparkle()
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
