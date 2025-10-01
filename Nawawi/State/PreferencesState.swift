//
//  PreferencesState.swift
//  Nawawi
//
//  Manages user preferences and app settings
//  Extracted from AppState following Single Responsibility Principle
//

import Foundation
import SwiftUI
import Combine
import ServiceManagement

@MainActor
class PreferencesState: ObservableObject {
    // MARK: - Language Preference
    @Published var selectedLanguage: AppLanguage = .english {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: "selectedLanguage")
        }
    }

    // MARK: - Launch Settings
    @AppStorage("launchAtLogin") var launchAtLogin = false {
        didSet {
            updateLaunchAtLogin()
        }
    }

    init() {
        loadLanguagePreference()
    }

    // MARK: - Public Methods

    func loadLanguagePreference() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            selectedLanguage = language
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
