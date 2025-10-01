//
//  NotificationManager.swift
//  Nawawi
//
//  Manages notification permissions and daily reminder scheduling
//  Extracted from AppState following Single Responsibility Principle
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    @Published var reminderEnabled = false {
        didSet {
            if reminderEnabled {
                scheduleReminder()
            } else {
                cancelReminder()
            }
        }
    }

    @Published var reminderHour = 9 {
        didSet { if reminderEnabled { scheduleReminder() } }
    }

    @Published var reminderMinute = 0 {
        didSet { if reminderEnabled { scheduleReminder() } }
    }

    @Published var hasActiveReminder = false

    @AppStorage("reminderEnabled") private var storedReminderEnabled = false
    @AppStorage("reminderHour") private var storedReminderHour = 9
    @AppStorage("reminderMinute") private var storedReminderMinute = 0

    init() {
        // Load saved preferences
        reminderEnabled = storedReminderEnabled
        reminderHour = storedReminderHour
        reminderMinute = storedReminderMinute
    }

    // MARK: - Public Methods

    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                print("Notification permission granted: \(granted)")
                completion(granted)
            } catch {
                print("Error requesting notification permission: \(error)")
                completion(false)
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

    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from 40 Hadith Nawawi"
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

    // MARK: - Private Methods

    func scheduleReminder() {
        guard reminderEnabled else {
            hasActiveReminder = false
            return
        }

        // First check notification permissions
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self = self else { return }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if settings.authorizationStatus == .authorized {
                    self.hasActiveReminder = true

                    // Remove existing notifications
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-hadith"])

                    // Create notification content
                    let content = UNMutableNotificationContent()
                    content.title = "Daily Hadith Reminder"
                    content.body = "Time to read today's hadith from the 40 Hadith of Imam Nawawi"
                    content.sound = .default
                    content.categoryIdentifier = "HADITH_REMINDER"

                    // Schedule for specific time each day
                    var dateComponents = DateComponents()
                    dateComponents.hour = self.reminderHour
                    dateComponents.minute = self.reminderMinute

                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                    let request = UNNotificationRequest(identifier: "daily-hadith", content: content, trigger: trigger)

                    UNUserNotificationCenter.current().add(request) { [weak self] error in
                        guard let self = self else { return }
                        if let error = error {
                            print("Error scheduling notification: \(error)")
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
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
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
                        guard let self = self else { return }
                        if granted {
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                self.scheduleReminder()
                            }
                        }
                    }
                }
            }
        }
    }

    func cancelReminder() {
        hasActiveReminder = false
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-hadith"])
    }
}
