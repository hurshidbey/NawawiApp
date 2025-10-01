//
//  SettingsContentView.swift
//  Nawawi
//
//  Unified settings content view
//  Eliminates duplicate settings UI between MenuBar and MainWindow
//

import SwiftUI
import UserNotifications
import Sparkle

struct SettingsContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var notificationManager: NotificationManager

    @State private var selectedTime = Date()
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Notifications Section
                notificationsSection

                // Startup Section
                startupSection

                // Favorites Section
                favoritesSection

                // Keyboard Shortcuts Section
                keyboardShortcutsSection

                // Updates Section
                updatesSection

                // About Section
                aboutSection
            }
            .padding()
        }
        .onAppear {
            loadNotificationSettings()
            checkPermissionStatus()
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("Notifications", systemImage: "bell")
                    .font(.headline)

                if permissionStatus == .denied {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text("Notifications are disabled in System Settings")
                            .font(.caption)
                            .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                    }

                    Button(action: openSystemSettings) {
                        Text("Open System Settings")
                            .foregroundColor(.black)
                    }
                    .buttonStyle(.link)
                } else if permissionStatus == .notDetermined {
                    Button(action: requestPermission) {
                        Text("Enable Notifications")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Toggle("Daily Reminder", isOn: $notificationManager.reminderEnabled)
                    .disabled(permissionStatus != .authorized)

                if notificationManager.reminderEnabled && permissionStatus == .authorized {
                    DatePicker("Reminder Time",
                              selection: $selectedTime,
                              displayedComponents: .hourAndMinute)
                        .onChange(of: selectedTime) { _, newTime in
                            updateReminderTime(newTime)
                        }

                    Button(action: {
                        notificationManager.sendTestNotification()
                    }) {
                        Text("Send Test Notification")
                            .foregroundColor(.black)
                    }
                    .buttonStyle(.link)
                }
            }
        }
    }

    // MARK: - Startup Section

    private var startupSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("Startup", systemImage: "power")
                    .font(.headline)

                Toggle("Launch at Login", isOn: $appState.launchAtLogin)
                    .help("Automatically launch the app when you log in to your Mac")
                    .onChange(of: appState.launchAtLogin) { _, _ in
                        appState.updateLaunchAtLogin()
                    }

                Text("The app will start in the menu bar when your Mac starts")
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.5, green: 0.5, blue: 0.5))
            }
        }
    }

    // MARK: - Favorites Section

    private var favoritesSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("Favorites", systemImage: "heart")
                    .font(.headline)

                if favoritesManager.favorites.isEmpty {
                    Text("No favorites yet")
                        .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                } else {
                    Text("\(favoritesManager.favorites.count) hadith\(favoritesManager.favorites.count == 1 ? "" : "s") marked as favorite")
                        .foregroundColor(.black)

                    Button(action: {
                        favoritesManager.clearAllFavorites()
                    }) {
                        Text("Clear All Favorites")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    // MARK: - Keyboard Shortcuts Section

    private var keyboardShortcutsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("Keyboard Shortcuts", systemImage: "keyboard")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    ShortcutRow(keys: "⌘ ←/→", action: "Navigate hadiths")
                    ShortcutRow(keys: "⌘ F", action: "Focus search")
                    ShortcutRow(keys: "⌘ L", action: "Toggle favorites")
                    ShortcutRow(keys: "⌘ R", action: "Random hadith")
                    ShortcutRow(keys: "⌘ ,", action: "Settings")
                    ShortcutRow(keys: "⌘ Q", action: "Quit app")
                    ShortcutRow(keys: "ESC", action: "Go back")
                }
            }
        }
    }

    // MARK: - Updates Section

    private var updatesSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("Updates", systemImage: "arrow.down.circle")
                    .font(.headline)

                Text("Automatic updates keep the app secure and add new features")
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: checkForUpdates) {
                    Text("Check for Updates...")
                        .foregroundColor(.black)
                }
                .buttonStyle(.link)
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("About", systemImage: "info.circle")
                    .font(.headline)

                Text("40 Hadith Nawawi")
                    .font(.body)
                    .foregroundColor(.black)
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                Text("A collection of forty hadiths compiled by Imam Nawawi")
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))

                Button(action: showAbout) {
                    Text("Credits & Attributions")
                        .foregroundColor(.black)
                }
                .buttonStyle(.link)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Helper Functions

    private func loadNotificationSettings() {
        var components = DateComponents()
        components.hour = notificationManager.reminderHour
        components.minute = notificationManager.reminderMinute
        selectedTime = Calendar.current.date(from: components) ?? Date()
    }

    private func checkPermissionStatus() {
        notificationManager.checkNotificationPermission { status in
            permissionStatus = status
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }

    private func requestPermission() {
        notificationManager.requestNotificationPermission { granted in
            checkPermissionStatus()
            if granted {
                notificationManager.reminderEnabled = true
            }
        }
    }

    private func updateReminderTime(_ newTime: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: newTime)
        notificationManager.reminderHour = components.hour ?? 9
        notificationManager.reminderMinute = components.minute ?? 0
    }

    private func checkForUpdates() {
        if let appDelegate = NSApp.delegate as? AppDelegate,
           let updater = appDelegate.updaterController {
            updater.checkForUpdates(nil)
        } else {
            let alert = NSAlert()
            alert.messageText = "Update Check"
            alert.informativeText = "Unable to check for updates. Please restart the app and try again."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func showAbout() {
        let aboutWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 700),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        aboutWindow.center()
        aboutWindow.title = "About 40 Hadith Nawawi"
        aboutWindow.contentView = NSHostingView(rootView: AboutView())
        aboutWindow.makeKeyAndOrderFront(nil)
    }
}
