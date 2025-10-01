//
//  OnboardingState.swift
//  Nawawi
//
//  Manages onboarding flow and first-run experience
//  Extracted from AppState following Single Responsibility Principle
//

import Foundation
import SwiftUI
import Combine

@MainActor
class OnboardingState: ObservableObject {
    // MARK: - Onboarding Properties
    @Published var showOnboarding = false

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        checkOnboardingStatus()
    }

    // MARK: - Public Methods

    func checkOnboardingStatus() {
        showOnboarding = !hasCompletedOnboarding
        print("🚀 OnboardingState - hasCompletedOnboarding: \(hasCompletedOnboarding), showOnboarding: \(showOnboarding)")
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        showOnboarding = false
        print("✅ Onboarding completed")
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        showOnboarding = true
        print("🔄 Onboarding reset")
    }

    var isOnboardingComplete: Bool {
        hasCompletedOnboarding
    }
}
