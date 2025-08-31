//
//  Settings.swift
//  Nawawi
//
//  Created by Khurshid Marazikov on 8/31/25.
//

import Foundation
import SwiftData

@Model
final class Settings {
    var notificationsEnabled: Bool
    var reminderInterval: ReminderInterval
    var customReminderTimes: [Date]
    var displayMode: DisplayMode
    var showArabicText: Bool
    var showEnglishTranslation: Bool
    var launchAtLogin: Bool
    var selectedTheme: Theme
    var fontSize: FontSize
    var lastHadithNumber: Int
    
    init() {
        self.notificationsEnabled = true
        self.reminderInterval = .daily
        self.customReminderTimes = []
        self.displayMode = .sequential
        self.showArabicText = true
        self.showEnglishTranslation = true
        self.launchAtLogin = false
        self.selectedTheme = .automatic
        self.fontSize = .medium
        self.lastHadithNumber = 1
    }
}

enum ReminderInterval: String, CaseIterable, Codable {
    case hourly = "Hourly"
    case threeHours = "Every 3 Hours"
    case sixHours = "Every 6 Hours"
    case daily = "Daily"
    case custom = "Custom Times"
    
    var timeInterval: TimeInterval? {
        switch self {
        case .hourly:
            return 3600
        case .threeHours:
            return 10800
        case .sixHours:
            return 21600
        case .daily:
            return 86400
        case .custom:
            return nil
        }
    }
}

enum DisplayMode: String, CaseIterable, Codable {
    case sequential = "Sequential"
    case random = "Random"
    case favoritesOnly = "Favorites Only"
}

enum Theme: String, CaseIterable, Codable {
    case automatic = "Automatic"
    case light = "Light"
    case dark = "Dark"
    case islamic = "Islamic Green"
}

enum FontSize: String, CaseIterable, Codable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"
    
    var arabicSize: CGFloat {
        switch self {
        case .small:
            return 18
        case .medium:
            return 22
        case .large:
            return 26
        case .extraLarge:
            return 30
        }
    }
    
    var englishSize: CGFloat {
        switch self {
        case .small:
            return 14
        case .medium:
            return 16
        case .large:
            return 18
        case .extraLarge:
            return 20
        }
    }
}