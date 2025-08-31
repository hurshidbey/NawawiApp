//
//  NotificationManager.swift
//  Nawawi
//
//  Created by Khurshid Marazikov on 8/31/25.
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

class NotificationManager: NSObject, ObservableObject {
    // Removed singleton - use dependency injection instead
    @Published var hasNotificationPermission = false
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        requestNotificationPermission()
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.hasNotificationPermission = granted
            }
            
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    func scheduleHadithNotification(hadith: Hadith?) {
        guard let hadith = hadith, hasNotificationPermission else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Hadith #\(hadith.number)"
        content.subtitle = hadith.narrator
        content.body = String(hadith.englishTranslation.prefix(200))
        content.sound = .default
        content.categoryIdentifier = "HADITH_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "hadith-\(hadith.number)-\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func scheduleCustomReminders(at times: [Date]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        for time in times {
            let components = Calendar.current.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let content = UNMutableNotificationContent()
            content.title = "Time for Hadith Reflection"
            content.body = "Open Nawawi to read today's hadith"
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: "custom-\(components.hour ?? 0)-\(components.minute ?? 0)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}