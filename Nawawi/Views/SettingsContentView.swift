//
//  SettingsContentView.swift
//  Nawawi
//
//  Shared settings component for both menu bar and windowed interfaces
//

import SwiftUI
import Sparkle

struct SettingsContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            // Notifications Section
            GroupBox(label: Label("Notifications", systemImage: "bell")
                .font(.nohemiHeadline)
                .foregroundColor(.black)) {
                VStack(alignment: .leading, spacing: 12) {

                    Toggle("Daily Reminder", isOn: $appState.reminderEnabled)
                        .onChange(of: appState.reminderEnabled) { _, enabled in
                            if enabled {
                                appState.scheduleReminder()
                            } else {
                                appState.cancelReminder()
                            }
                        }

                }
            }

            // Updates Section
            GroupBox(label: Label("Updates", systemImage: "arrow.down.circle")
                .font(.nohemiHeadline)
                .foregroundColor(.black)) {
                VStack(alignment: .leading, spacing: 12) {

                    Button(action: {
                        if let appDelegate = NSApp.delegate as? AppDelegate,
                           let updater = appDelegate.updaterController {
                            updater.checkForUpdates(nil)
                        }
                    }) {
                        Text("Check for Updates...")
                    }

                    Text("Automatic update checks: Enabled")
                        .font(.nohemiCaption)
                        .foregroundColor(.gray)
                }
            }

            // Favorites Section
            GroupBox(label: Label("Favorites", systemImage: "heart")
                .font(.nohemiHeadline)
                .foregroundColor(.black)) {
                VStack(alignment: .leading, spacing: 12) {

                    if appState.favorites.isEmpty {
                        Text("No favorites yet")
                            .foregroundColor(.gray)
                    } else {
                        Text("\(appState.favorites.count) hadith\(appState.favorites.count == 1 ? "" : "s") marked as favorite")
                            .foregroundColor(.black)

                        Button(action: {
                            appState.favorites.removeAll()
                            appState.saveFavorites()
                        }) {
                            Text("Clear All Favorites")
                                .foregroundColor(.red)
                        }
                    }
                }
            }

            // About Section
            GroupBox(label: Label("About", systemImage: "info.circle")
                .font(.nohemiHeadline)
                .foregroundColor(.black)) {
                VStack(alignment: .leading, spacing: 12) {

                    Text("40 Hadith Nawawi")
                        .font(.nohemiBody)
                        .foregroundColor(.black)
                    Text("Version 1.0.0")
                        .font(.nohemiCaption)
                        .foregroundColor(.black)
                    Text("A collection of forty hadiths compiled by Imam Nawawi")
                        .font(.nohemiCaption)
                        .foregroundColor(.black)
                }
            }
        }
        .padding()
    }
}
