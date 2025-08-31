//
//  SettingsView.swift
//  Nawawi
//
//  Created by Khurshid Marazikov on 8/31/25.
//

import SwiftUI
import SwiftData
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var hadithManager: HadithManager
    @EnvironmentObject var notificationManager: NotificationManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsArray: [Settings]
    
    @State private var selectedTab = "general"
    @State private var customTimeToAdd = Date()
    
    // Local state copies to prevent immediate updates
    @State private var localDisplayMode: DisplayMode = .sequential
    @State private var localShowArabicText: Bool = true
    @State private var localShowEnglishTranslation: Bool = true
    @State private var localNotificationsEnabled: Bool = true
    @State private var localReminderInterval: ReminderInterval = .daily
    @State private var localTheme: Theme = .automatic
    @State private var localFontSize: FontSize = .medium
    
    var settings: Settings {
        settingsArray.first ?? Settings()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            TabView(selection: $selectedTab) {
                GeneralSettingsView(
                    displayMode: $localDisplayMode,
                    showArabicText: $localShowArabicText,
                    showEnglishTranslation: $localShowEnglishTranslation,
                    launchAtLogin: settings.launchAtLogin
                )
                    .tabItem {
                        Label("General", systemImage: "gearshape")
                    }
                    .tag("general")
                
                NotificationSettingsView(
                    notificationsEnabled: $localNotificationsEnabled,
                    reminderInterval: $localReminderInterval,
                    customReminderTimes: settings.customReminderTimes,
                    notificationManager: notificationManager
                )
                    .tabItem {
                        Label("Notifications", systemImage: "bell")
                    }
                    .tag("notifications")
                
                AppearanceSettingsView(
                    theme: $localTheme,
                    fontSize: $localFontSize
                )
                    .tabItem {
                        Label("Appearance", systemImage: "paintbrush")
                    }
                    .tag("appearance")
            }
            .padding()
        }
        .frame(width: 600, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            if settingsArray.isEmpty {
                let newSettings = Settings()
                modelContext.insert(newSettings)
            }
            // Initialize local state from settings
            loadSettings()
        }
        .onDisappear {
            // Save settings when view disappears
            saveSettings()
        }
    }
    
    private func loadSettings() {
        localDisplayMode = settings.displayMode
        localShowArabicText = settings.showArabicText
        localShowEnglishTranslation = settings.showEnglishTranslation
        localNotificationsEnabled = settings.notificationsEnabled
        localReminderInterval = settings.reminderInterval
        localTheme = settings.selectedTheme
        localFontSize = settings.fontSize
    }
    
    private func saveSettings() {
        settings.displayMode = localDisplayMode
        settings.showArabicText = localShowArabicText
        settings.showEnglishTranslation = localShowEnglishTranslation
        settings.notificationsEnabled = localNotificationsEnabled
        settings.reminderInterval = localReminderInterval
        settings.selectedTheme = localTheme
        settings.fontSize = localFontSize
        hadithManager.refreshSettings(settings)
    }
}

struct GeneralSettingsView: View {
    @Binding var displayMode: DisplayMode
    @Binding var showArabicText: Bool
    @Binding var showEnglishTranslation: Bool
    let launchAtLogin: Bool
    @State private var localLaunchAtLogin = false
    
    var body: some View {
        Form {
            Section("Display Options") {
                Picker("Display Mode", selection: $displayMode) {
                    ForEach(DisplayMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                
                Toggle("Show Arabic Text", isOn: $showArabicText)
                
                Toggle("Show English Translation", isOn: $showEnglishTranslation)
            }
            
            Section("System") {
                Toggle("Launch at Login", isOn: $localLaunchAtLogin)
                    .onChange(of: localLaunchAtLogin) { _, newValue in
                        Task {
                            do {
                                if newValue {
                                    if SMAppService.mainApp.status == .enabled {
                                        return // Already enabled
                                    }
                                    try SMAppService.mainApp.register()
                                } else {
                                    if SMAppService.mainApp.status == .notRegistered {
                                        return // Already disabled
                                    }
                                    try SMAppService.mainApp.unregister()
                                }
                            } catch {
                                print("Failed to update launch at login: \(error)")
                                // Reset toggle on failure
                                await MainActor.run {
                                    localLaunchAtLogin = !newValue
                                }
                            }
                        }
                    }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            // Check actual status from system
            localLaunchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

struct NotificationSettingsView: View {
    @Binding var notificationsEnabled: Bool
    @Binding var reminderInterval: ReminderInterval
    let customReminderTimes: [Date]
    let notificationManager: NotificationManager
    @State private var customTimes: [Date] = []
    @State private var newCustomTime = Date()
    
    var body: some View {
        Form {
            Section("Reminder Settings") {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                
                Picker("Reminder Interval", selection: $reminderInterval) {
                    ForEach(ReminderInterval.allCases, id: \.self) { interval in
                        Text(interval.rawValue).tag(interval)
                    }
                }
                .disabled(!notificationsEnabled)
            }
            
            if reminderInterval == .custom {
                Section("Custom Times") {
                    ForEach(customTimes, id: \.self) { time in
                        HStack {
                            Text(time, style: .time)
                            Spacer()
                            Button(action: {
                                customTimes.removeAll { $0 == time }
                                notificationManager.scheduleCustomReminders(at: customTimes)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    HStack {
                        DatePicker("Add Time", selection: $newCustomTime, displayedComponents: .hourAndMinute)
                        Button("Add") {
                            customTimes.append(newCustomTime)
                            notificationManager.scheduleCustomReminders(at: customTimes)
                        }
                    }
                }
            }
            
            Section {
                Button("Request Notification Permission") {
                    notificationManager.requestNotificationPermission()
                }
                .disabled(notificationManager.hasNotificationPermission)
                
                if notificationManager.hasNotificationPermission {
                    Label("Notifications Enabled", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            customTimes = customReminderTimes
        }
    }
}

struct AppearanceSettingsView: View {
    @Binding var theme: Theme
    @Binding var fontSize: FontSize
    
    var body: some View {
        Form {
            Section("Theme") {
                Picker("Theme", selection: $theme) {
                    ForEach(Theme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
            }
            
            Section("Font Size") {
                Picker("Text Size", selection: $fontSize) {
                    ForEach(FontSize.allCases, id: \.self) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Preview:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                        .font(.custom("SF Arabic", size: fontSize.arabicSize))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    Text("In the name of Allah, the Most Gracious, the Most Merciful")
                        .font(.system(size: fontSize.englishSize))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                )
            }
        }
        .formStyle(.grouped)
    }
}