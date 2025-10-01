//
//  NavigationState.swift
//  Nawawi
//
//  Manages hadith navigation state and window coordination
//  Extracted from AppState following Single Responsibility Principle
//

import Foundation
import SwiftUI
import Combine

@MainActor
class NavigationState: ObservableObject {
    // MARK: - Navigation Properties
    @Published var currentHadithIndex = 0
    @Published var pendingHadithNavigation: Int? = nil
    @Published var shouldOpenMainWindow = false
    @Published var lastViewedDate = Date()

    // MARK: - Persistence
    @AppStorage("lastHadithIndex") private var savedIndex = 0

    init() {
        loadSavedIndex()
    }

    // MARK: - Public Methods

    func navigateTo(hadithIndex: Int) {
        currentHadithIndex = hadithIndex
        saveCurrentIndex()
    }

    func setPendingNavigation(to index: Int, openWindow: Bool = false) {
        pendingHadithNavigation = index
        shouldOpenMainWindow = openWindow
    }

    func clearPendingNavigation() {
        pendingHadithNavigation = nil
        shouldOpenMainWindow = false
    }

    func saveCurrentIndex() {
        savedIndex = currentHadithIndex
    }

    func loadSavedIndex() {
        currentHadithIndex = savedIndex
    }

    func updateLastViewed() {
        lastViewedDate = Date()
    }
}
