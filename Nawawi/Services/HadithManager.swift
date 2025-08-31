//
//  HadithManager.swift
//  Nawawi
//
//  Created by Khurshid Marazikov on 8/31/25.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class HadithManager: ObservableObject {
    @Published var currentHadith: Hadith?
    @Published var hadiths: [Hadith] = []
    @Published var settings: Settings?
    
    private var timer: Timer?
    private var hasLoadedHadiths = false
    private weak var notificationManager: NotificationManager?
    
    init() {
        loadHadiths()
        setupTimer()
    }
    
    func setNotificationManager(_ manager: NotificationManager) {
        self.notificationManager = manager
    }
    
    func loadHadiths() {
        // Don't reload if already loaded
        guard !hasLoadedHadiths else { return }
        
        guard let url = Bundle.main.url(forResource: "hadiths", withExtension: "json") else {
            print("Failed to find hadiths.json in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let hadithDataArray = try decoder.decode([HadithData].self, from: data)
            
            // Validate data before using
            guard !hadithDataArray.isEmpty else {
                print("Warning: Empty hadith array loaded")
                return
            }
            
            // Validate each hadith has required content
            let validHadiths = hadithDataArray.compactMap { data -> Hadith? in
                guard data.number > 0 && data.number <= 42,
                      !data.arabicText.isEmpty,
                      !data.englishTranslation.isEmpty,
                      !data.narrator.isEmpty else {
                    print("Warning: Invalid hadith data for number \(data.number)")
                    return nil
                }
                
                return Hadith(number: data.number,
                             arabicText: data.arabicText,
                             englishTranslation: data.englishTranslation,
                             narrator: data.narrator)
            }
            
            guard !validHadiths.isEmpty else {
                print("Error: No valid hadiths after validation")
                return
            }
            
            self.hadiths = validHadiths
            hasLoadedHadiths = true
            
            // Only select initial hadith if none is selected
            if currentHadith == nil {
                selectNextHadith()
            }
        } catch {
            print("Failed to load or decode hadiths: \(error.localizedDescription)")
            // Consider showing user-facing error
        }
    }
    
    func selectNextHadith() {
        guard !hadiths.isEmpty else { return }
        
        if let settings = settings {
            switch settings.displayMode {
            case .sequential:
                // Fix: Should be modulo 40 (not 42) as there are 40 hadiths
                let nextNumber = (settings.lastHadithNumber % 40) + 1
                currentHadith = hadiths.first(where: { $0.number == nextNumber })
                settings.lastHadithNumber = nextNumber
            case .random:
                currentHadith = hadiths.randomElement()
            case .favoritesOnly:
                let favorites = hadiths.filter { $0.isFavorite }
                currentHadith = favorites.isEmpty ? hadiths.randomElement() : favorites.randomElement()
            }
        } else {
            currentHadith = hadiths.randomElement()
        }
        
        currentHadith?.lastViewedDate = Date()
    }
    
    func toggleFavorite(for hadith: Hadith) {
        hadith.isFavorite.toggle()
    }
    
    func setupTimer() {
        timer?.invalidate()
        
        guard let settings = settings,
              settings.notificationsEnabled,
              let interval = settings.reminderInterval.timeInterval else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.selectNextHadith()
            self.notificationManager?.scheduleHadithNotification(hadith: self.currentHadith)
        }
    }
    
    func refreshSettings(_ newSettings: Settings) {
        self.settings = newSettings
        setupTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
}