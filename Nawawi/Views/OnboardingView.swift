//
//  OnboardingView.swift
//  Nawawi
//
//  Created by Claude Code on 10/1/25.
//

import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notificationManager: NotificationManager
    @Environment(\.openWindow) private var openWindow
    @State private var currentPage = 0
    @State private var selectedTime = Date()
    @State private var reminderEnabled = true
    @State private var isRequestingPermission = false
    @State private var permissionGranted = false
    @State private var showingPermissionDenied = false

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.nawawi_cream,
                    Color.nawawi_softCream
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                if currentPage == 0 {
                    welcomePage
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else if currentPage == 1 {
                    reminderSetupPage
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    completionPage
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .padding(40)
        }
        .frame(width: 600, height: 550)
        .onAppear {
            // Initialize selected time with default 9:00 AM
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            selectedTime = Calendar.current.date(from: components) ?? Date()
        }
    }

    // MARK: - Welcome Page
    private var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()

            // App icon or symbol
            Image(systemName: "book.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.nawawi_darkGreen)
                .symbolEffect(.bounce, value: currentPage)

            // Title
            VStack(spacing: 12) {
                Text("40 Hadith Nawawi")
                    .font(.nohemiDisplay)
                    .foregroundColor(.black)

                Text("أربعون النووية")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color.nawawi_darkGreen)
            }

            // Description
            VStack(spacing: 16) {
                Text("A collection of forty authentic hadiths compiled by Imam Nawawi")
                    .font(.nohemiBody)
                    .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("Study, memorize, and reflect on these timeless teachings")
                    .font(.nohemiBody)
                    .foregroundStyle(Color(red: 0.5, green: 0.5, blue: 0.5))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)

            Spacer()

            // Continue button
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentPage = 1
                }
            }) {
                HStack {
                    Text("Get Started")
                        .font(.nohemiHeadline)
                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.nawawi_darkGreen)
                )
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 400)

            // Skip button
            Button(action: {
                completeOnboarding()
            }) {
                Text("Skip for now")
                    .font(.nohemiBody)
                    .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Reminder Setup Page
    private var reminderSetupPage: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 70))
                .foregroundStyle(Color.nawawi_darkGreen)
                .symbolEffect(.pulse, value: currentPage)

            // Title
            VStack(spacing: 12) {
                Text("Daily Reminder")
                    .font(.nohemiTitle)
                    .foregroundColor(.black)

                Text("Stay connected with daily wisdom")
                    .font(.nohemiBody)
                    .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                    .multilineTextAlignment(.center)
            }

            // Reminder configuration
            VStack(spacing: 24) {
                Toggle(isOn: $reminderEnabled) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(Color.nawawi_darkGreen)
                        Text("Enable daily hadith reminder")
                            .font(.nohemiBody)
                            .foregroundColor(.black)
                    }
                }
                .toggleStyle(.switch)
                .tint(Color.nawawi_darkGreen)
                .padding(.horizontal, 30)

                if reminderEnabled {
                    VStack(spacing: 16) {
                        Text("When would you like to be reminded?")
                            .font(.nohemiBody)
                            .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))

                        DatePicker(
                            "Reminder Time",
                            selection: $selectedTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.stepperField)
                        .labelsHidden()
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.5))
                        )

                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.caption)
                                .foregroundStyle(Color.nawawi_darkGreen)
                            Text("You'll receive a random hadith each day at this time")
                                .font(.nohemiCaption)
                                .foregroundStyle(Color(red: 0.5, green: 0.5, blue: 0.5))
                        }
                        .padding(.horizontal, 30)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }

            Spacer()

            // Navigation buttons
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        currentPage = 0
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .font(.nohemiBody)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.black.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Button(action: {
                    if reminderEnabled {
                        requestNotificationPermission()
                    } else {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentPage = 2
                        }
                    }
                }) {
                    HStack {
                        Text(reminderEnabled ? "Enable Notifications" : "Continue")
                            .font(.nohemiHeadline)
                        if !reminderEnabled {
                            Image(systemName: "arrow.right")
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.nawawi_darkGreen)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isRequestingPermission)
            }
            .frame(maxWidth: 500)

            // Skip button
            Button(action: {
                completeOnboarding()
            }) {
                Text("Skip for now")
                    .font(.nohemiBody)
                    .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
            }
            .buttonStyle(.plain)
        }
        .alert("Notifications Disabled", isPresented: $showingPermissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Continue Anyway") {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentPage = 2
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable notifications in System Settings to receive daily hadith reminders.")
        }
    }

    // MARK: - Completion Page
    private var completionPage: some View {
        VStack(spacing: 30) {
            Spacer()

            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.green)
                .symbolEffect(.bounce, value: currentPage)

            // Title
            VStack(spacing: 12) {
                Text("All Set!")
                    .font(.nohemiDisplay)
                    .foregroundColor(.black)

                if reminderEnabled && permissionGranted {
                    VStack(spacing: 8) {
                        Text("You'll receive your first reminder at")
                            .font(.nohemiBody)
                            .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))

                        Text(selectedTime.formatted(date: .omitted, time: .shortened))
                            .font(.nohemiTitle)
                            .foregroundColor(Color.nawawi_darkGreen)
                    }
                } else {
                    Text("You can enable reminders anytime in Settings")
                        .font(.nohemiBody)
                        .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            // Start button
            Button(action: {
                completeOnboarding()
            }) {
                HStack {
                    Text("Start Learning")
                        .font(.nohemiHeadline)
                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.nawawi_darkGreen)
                )
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 400)
        }
    }

    // MARK: - Helper Functions
    private func requestNotificationPermission() {
        isRequestingPermission = true

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                isRequestingPermission = false
                permissionGranted = granted

                if granted {
                    // Save reminder settings
                    let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                    notificationManager.reminderHour = components.hour ?? 9
                    notificationManager.reminderMinute = components.minute ?? 0
                    notificationManager.reminderEnabled = true

                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        currentPage = 2
                    }
                } else {
                    showingPermissionDenied = true
                }
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        onComplete()

        // Open main window after onboarding completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            openWindow(id: "main-window")
        }
    }
}

#Preview {
    OnboardingView {
        print("Onboarding completed")
    }
    .environmentObject(AppState())
}
