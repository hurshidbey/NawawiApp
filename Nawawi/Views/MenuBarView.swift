//
//  MenuBarView.swift
//  Nawawi
//
//  Created by Khurshid Marazikov on 8/31/25.
//

import SwiftUI
import UserNotifications
import AppKit
import Sparkle

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: HadithDataManager
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var hadithActionService: HadithActionService
    @Environment(\.openWindow) private var openWindow
    @State private var showFullHadith = false
    @State private var showSettings = false
    @State private var showingFavoritesOnly = false
    @State private var searchText = ""
    @State private var currentView: ViewMode = .main
    @State private var windowSize = CGSize(width: 450, height: 600)
    @State private var showExportMenu = false

    @FocusState private var isSearchFocused: Bool
    @State private var keyboardMonitor: Any?

    enum ViewMode {
        case main
        case settings
        case detail
    }

    var currentHadith: Hadith? {
        let displayHadiths = filteredHadiths
        guard !displayHadiths.isEmpty else {
            return nil
        }
        // Validate and clamp index without mutation
        let safeIndex = min(max(0, appState.currentHadithIndex), displayHadiths.count - 1)
        return displayHadiths[safeIndex]
    }

    // Helper function to validate and update index safely
    private func validateCurrentIndex() {
        let displayHadiths = filteredHadiths
        if displayHadiths.isEmpty {
            if appState.currentHadithIndex != 0 {
                appState.currentHadithIndex = 0
            }
            return
        }
        let safeIndex = min(max(0, appState.currentHadithIndex), displayHadiths.count - 1)
        if safeIndex != appState.currentHadithIndex {
            appState.currentHadithIndex = safeIndex
        }
    }

    var filteredHadiths: [Hadith] {
        dataManager.searchHadiths(
            query: searchText,
            language: appState.selectedLanguage,
            favoritesOnly: showingFavoritesOnly,
            favorites: favoritesManager.favorites
        )
    }

    var body: some View {
        ZStack {
            // Modern cream background with subtle texture
            ModernBackgroundView()

            switch currentView {
            case .settings:
                MenuBarSettingsView(currentView: $currentView, windowSize: $windowSize)
                    .environmentObject(appState)
                    .environmentObject(favoritesManager)
                    .environmentObject(notificationManager)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .detail:
                if let hadith = currentHadith {
                    HadithDetailInlineView(
                        hadith: hadith,
                        currentView: $currentView,
                        windowSize: $windowSize
                    )
                    .environmentObject(appState)
                    .environmentObject(dataManager)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
                }
            case .main:
                VStack(spacing: 0) {
                    // Enhanced Header
                    EnhancedHeaderView(
                        searchText: $searchText,
                        isSearchFocused: $isSearchFocused,
                        showingFavoritesOnly: $showingFavoritesOnly
                    )
                    .environmentObject(appState)
                    .environmentObject(dataManager)

                    // Loading or Error state
                    if dataManager.isLoading {
                        LoadingView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = dataManager.error {
                        ErrorView(error: error) {
                            dataManager.loadHadiths()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let hadith = currentHadith {
                        // Main content with animation
                        ScrollView {
                            VStack(spacing: 16) {
                                // Progress indicator
                                HadithProgressIndicator(
                                    current: appState.currentHadithIndex + 1,
                                    total: filteredHadiths.count,
                                    selectedIndex: $appState.currentHadithIndex
                                )
                                .padding(.top, 8)

                                // Enhanced Hadith card
                                EnhancedHadithCard(
                                    hadith: hadith,
                                    searchHighlight: searchText
                                )
                                .environmentObject(appState)
                                .environmentObject(dataManager)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4)) {
                                        currentView = .detail
                                    }
                                }
                                .transition(.asymmetric(
                                    insertion: .slide,
                                    removal: .scale.combined(with: .opacity)
                                ))
                                .id(hadith.id)
                            }
                            .padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ContentUnavailableView(
                            "No Hadiths",
                            systemImage: "book.closed",
                            description: Text(searchText.isEmpty ? "No hadiths available" : "No hadiths match your search")
                                .foregroundColor(.black)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // Enhanced toolbar
                    EnhancedToolbarView(
                        showingFavoritesOnly: $showingFavoritesOnly,
                        showSettings: $showSettings,
                        filteredCount: filteredHadiths.count,
                        currentView: $currentView,
                        navigateNext: navigateToNextHadith,
                        navigatePrevious: navigateToPreviousHadith,
                        onRandomHadith: showRandomHadith,
                        onExport: { showExportMenu.toggle() }
                    )
                    .environmentObject(appState)
                }
            }
        }
        .frame(width: windowSize.width, height: windowSize.height)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentView)
        .onAppear {
            setupKeyboardShortcuts()
            validateCurrentIndex()

            // Check if we need to show onboarding on first launch
            print("📱 MenuBarView.onAppear - showOnboarding: \(appState.showOnboarding)")
            if appState.showOnboarding {
                print("✅ Attempting to open onboarding window...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Use SwiftUI's openWindow
                    openWindow(id: "onboarding")

                    // Fallback: activate the app to bring windows forward
                    NSApp.activate(ignoringOtherApps: true)

                    // Force window to front if it exists
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if let window = NSApp.windows.first(where: { $0.title == "Welcome" }) {
                            window.makeKeyAndOrderFront(nil)
                            print("🪟 Found and activated Welcome window")
                        } else {
                            print("⚠️ Welcome window not found in NSApp.windows: \(NSApp.windows.map { $0.title })")
                        }
                    }
                }
            } else {
                print("❌ Onboarding already completed")
            }
        }
        .onDisappear {
            removeKeyboardShortcuts()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenHadith"))) { notification in
            if let hadithIndex = notification.userInfo?["hadithIndex"] as? Int {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    appState.currentHadithIndex = hadithIndex
                    currentView = .main
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenMainWindow"))) { _ in
            print("🪟 MenuBarView: Received OpenMainWindow request")
            openWindow(id: "main-window")
            print("🪟 Called openWindow(id: main-window)")
        }
        .onReceive(appState.$showSettings) { show in
            if show {
                currentView = .settings
            }
        }
        .onReceive(appState.$shouldOpenMainWindow) { shouldOpen in
            if shouldOpen {
                print("🪟 MenuBarView: shouldOpenMainWindow flag triggered")
                openWindow(id: "main-window")
                // Reset flag
                DispatchQueue.main.async {
                    appState.shouldOpenMainWindow = false
                }
            }
        }
    }

    private func setupKeyboardShortcuts() {
        // Remove existing monitor if any
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
        }

        // Add new monitor and store reference
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard NSApp.isActive else { return event }

            switch event.keyCode {
            case 123: // Left arrow
                if event.modifierFlags.contains(.command) {
                    navigateToPreviousHadith()
                    return nil
                }
            case 124: // Right arrow
                if event.modifierFlags.contains(.command) {
                    navigateToNextHadith()
                    return nil
                }
            case 15: // R key
                if event.modifierFlags.contains(.command) {
                    showRandomHadith()
                    return nil
                }
            case 3: // F key
                if event.modifierFlags.contains(.command) {
                    isSearchFocused = true
                    return nil
                }
            default:
                break
            }
            return event
        }
    }

    private func removeKeyboardShortcuts() {
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardMonitor = nil
        }
    }

    func navigateToNextHadith() {
        guard !filteredHadiths.isEmpty else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            let nextIndex = (appState.currentHadithIndex + 1) % filteredHadiths.count
            appState.currentHadithIndex = nextIndex
            appState.saveCurrentIndex()
        }
    }

    func navigateToPreviousHadith() {
        guard !filteredHadiths.isEmpty else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            let prevIndex = appState.currentHadithIndex == 0 ?
                filteredHadiths.count - 1 : appState.currentHadithIndex - 1
            appState.currentHadithIndex = prevIndex
            appState.saveCurrentIndex()
        }
    }

    func showRandomHadith() {
        guard !filteredHadiths.isEmpty else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            let randomIndex = Int.random(in: 0..<filteredHadiths.count)
            appState.currentHadithIndex = randomIndex
            appState.saveCurrentIndex()
        }
    }
}

// MARK: - Enhanced Hadith Card
struct EnhancedHadithCard: View {
    let hadith: Hadith
    let searchHighlight: String
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: HadithDataManager
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var hadithActionService: HadithActionService
    @State private var isHovered = false
    @State private var isFavoriteAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with animation
            HStack {
                Label {
                    Text("Hadith #\(hadith.number)")
                        .font(.nohemiCaption)
                } icon: {
                    Image(systemName: "number.circle.fill")
                        .font(.nohemiCaption)
                        .symbolRenderingMode(.hierarchical)
                }
                .foregroundStyle(.black)

                Spacer()

                // Export button
                Menu {
                    Button(action: { hadithActionService.exportToClipboard(hadith, format: .plain, dataManager: dataManager) }) {
                        Label("Copy as Plain Text", systemImage: "doc.on.doc")
                    }
                    Button(action: { hadithActionService.exportToClipboard(hadith, format: .markdown, dataManager: dataManager) }) {
                        Label("Copy as Markdown", systemImage: "text.badge.checkmark")
                    }
                    Button(action: { hadithActionService.shareHadith(hadith, dataManager: dataManager) }) {
                        Label("Share...", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: hadithActionService.copiedToClipboard ? "checkmark.circle.fill" : "ellipsis.circle")
                        .foregroundStyle(hadithActionService.copiedToClipboard ? .green : Color(red: 0.4, green: 0.4, blue: 0.4))
                        .symbolEffect(.bounce, value: hadithActionService.copiedToClipboard)
                }
                .menuStyle(.borderlessButton)

                // Favorite button with enhanced animation
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        favoritesManager.toggleFavorite(hadith.number)
                        isFavoriteAnimating = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isFavoriteAnimating = false
                    }
                }) {
                    Image(systemName: favoritesManager.isFavorite(hadith.number) ? "heart.fill" : "heart")
                        .foregroundStyle(favoritesManager.isFavorite(hadith.number) ? Color.nawawi_darkGreen : .gray)
                        .symbolEffect(.bounce, value: favoritesManager.isFavorite(hadith.number))
                        .scaleEffect(isFavoriteAnimating ? 1.2 : 1.0)
                }
                .buttonStyle(.plain)
            }

            // Arabic text with glass background (always shown first according to Islamic practice)
                VStack(alignment: .trailing, spacing: 8) {
                    if !searchHighlight.isEmpty && hadith.arabicText.contains(searchHighlight) {
                        HighlightedText(hadith.arabicText, highlight: searchHighlight, font: .system(size: 22))
                            .lineSpacing(.lineSpacing_arabicCompact)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .environment(\.layoutDirection, .rightToLeft)
                            .textSelection(.enabled)
                    } else {
                        Text(hadith.arabicText)
                            .font(.nohemiArabicBody)
                            .lineSpacing(.lineSpacing_arabicCompact)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .environment(\.layoutDirection, .rightToLeft)
                            .textSelection(.enabled)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.nawawi_softCream)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.3), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                )

            // Translation with highlighting
            Group {
                switch appState.selectedLanguage {
                case .arabic:
                    EmptyView()
                case .english:
                    if !searchHighlight.isEmpty && hadith.englishTranslation.localizedCaseInsensitiveContains(searchHighlight) {
                        HighlightedText(hadith.englishTranslation, highlight: searchHighlight, font: .system(size: 15))
                            .foregroundColor(.nawawi_bodyText)
                            .lineSpacing(.lineSpacing_normal)
                            .textSelection(.enabled)
                    } else {
                        Text(hadith.englishTranslation)
                            .font(.nohemiListTitle)
                            .foregroundColor(.nawawi_bodyText)
                            .lineSpacing(.lineSpacing_normal)
                            .textSelection(.enabled)
                    }
                }
            }

            // Narrator with icon
            Label {
                if !searchHighlight.isEmpty && hadith.narrator.localizedCaseInsensitiveContains(searchHighlight) {
                    HighlightedText(hadith.narrator, highlight: searchHighlight, font: .caption)
                        .foregroundStyle(Color.nawawi_captionText)
                } else {
                    Text(hadith.narrator)
                        .font(.nohemiCaption)
                        .foregroundStyle(Color.nawawi_captionText)
                }
            } icon: {
                Image(systemName: "person.circle.fill")
                    .font(.nohemiCaption)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.nawawi_surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.nawawi_darkGreen.opacity(isHovered ? 0.15 : 0.08), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        )
        .nawawi_cardShadow(elevated: isHovered)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Enhanced Toolbar
struct EnhancedToolbarView: View {
    @Binding var showingFavoritesOnly: Bool
    @Binding var showSettings: Bool
    let filteredCount: Int
    @Binding var currentView: MenuBarView.ViewMode
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow
    let navigateNext: () -> Void
    let navigatePrevious: () -> Void
    let onRandomHadith: () -> Void
    let onExport: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            // Navigation group with subtle background
            HStack(spacing: 16) {
                Button(action: navigatePrevious) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                }
                .buttonStyle(.plain)
                .disabled(filteredCount == 0)
                .keyboardShortcut(.leftArrow, modifiers: [.command])

                Text("\(filteredCount > 0 ? appState.currentHadithIndex + 1 : 0) / \(filteredCount)")
                    .font(.nohemiNumber)
                    .foregroundStyle(.black)
                    .monospacedDigit()
                    .frame(minWidth: 60)

                Button(action: navigateNext) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                }
                .buttonStyle(.plain)
                .disabled(filteredCount == 0)
                .keyboardShortcut(.rightArrow, modifiers: [.command])
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.3), in: Capsule())

            Spacer()

            // Action buttons with consistent spacing
            HStack(spacing: 20) {
                Button(action: onRandomHadith) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                }
                .buttonStyle(.plain)
                .help("Random Hadith (⌘R)")
                .keyboardShortcut("r", modifiers: [.command])

                Button(action: onExport) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                }
                .buttonStyle(.plain)
                .help("Export")

                Button(action: {
                    // Open main window using AppKit
                    if let window = NSApp.windows.first(where: { $0.title == "40 Hadith Nawawi" }) {
                        window.makeKeyAndOrderFront(nil)
                        NSApp.activate(ignoringOtherApps: true)
                    } else {
                        // Use SwiftUI openWindow to create new window
                        openWindow(id: "main-window")
                        // Activate after opening
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NSApp.activate(ignoringOtherApps: true)
                        }
                    }
                }) {
                    Image(systemName: "macwindow")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                }
                .buttonStyle(.plain)
                .help("Open Main Window")
                .keyboardShortcut("m", modifiers: [.command])

                Button(action: { currentView = .settings }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                }
                .buttonStyle(.plain)
                .help("Settings")
                .keyboardShortcut(",", modifiers: [.command])
            }

            // Power button separated with more space
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Image(systemName: "power.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.red)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .help("Quit (⌘Q)")
            .keyboardShortcut("q", modifiers: [.command])
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.nawawi_surface)
    }
}

// MARK: - Enhanced Detail View
struct HadithDetailInlineView: View {
    let hadith: Hadith
    @Binding var currentView: MenuBarView.ViewMode
    @Binding var windowSize: CGSize
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: HadithDataManager
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var hadithActionService: HadithActionService

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hadith #\(hadith.number)")
                        .font(.title2.bold())
                        .foregroundColor(.black)

                    Label(hadith.narrator, systemImage: "person.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                }

                Spacer()

                HStack(spacing: 16) {
                    // Favorite button
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            favoritesManager.toggleFavorite(hadith.number)
                        }
                    }) {
                        Image(systemName: favoritesManager.isFavorite(hadith.number) ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundStyle(favoritesManager.isFavorite(hadith.number) ? .red : .gray)
                            .symbolEffect(.bounce, value: favoritesManager.isFavorite(hadith.number))
                    }
                    .buttonStyle(.plain)

                    // Export menu
                    Menu {
                        Button(action: { hadithActionService.exportToClipboard(hadith, format: .plain, dataManager: dataManager) }) {
                            Label("Export as Text", systemImage: "doc.text")
                        }
                        Button(action: { hadithActionService.exportToClipboard(hadith, format: .markdown, dataManager: dataManager) }) {
                            Label("Export as Markdown", systemImage: "text.badge.checkmark")
                        }
                        Button(action: { hadithActionService.exportToClipboard(hadith, format: .json, dataManager: dataManager) }) {
                            Label("Export as JSON", systemImage: "curlybraces")
                        }
                        Divider()
                        Button(action: { hadithActionService.shareHadith(hadith, dataManager: dataManager) }) {
                            Label("Share...", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: hadithActionService.copiedToClipboard ? "checkmark.circle.fill" : "square.and.arrow.up")
                            .font(.title3)
                            .foregroundStyle(hadithActionService.copiedToClipboard ? .green : .gray)
                            .symbolEffect(.bounce, value: hadithActionService.copiedToClipboard)
                    }
                    .menuStyle(.borderlessButton)

                    // Back button
                    Button(action: {
                        withAnimation(.spring(response: 0.4)) {
                            currentView = .main
                        }
                    }) {
                        Label("Back", systemImage: "arrow.left.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                }
            }
            .padding()

            Divider()
                .opacity(0.3)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Language selector inline
                    Picker("Language", selection: $appState.selectedLanguage) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            HStack {
                                Text(language.flag)
                                    .foregroundColor(.black)
                                Text(language.displayName)
                                    .foregroundColor(.black)
                            }
                            .tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Arabic text (always shown first according to Islamic practice)
                        VStack(alignment: .trailing, spacing: 10) {
                            Text("Arabic Text")
                                .font(.caption)
                                .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(hadith.arabicText)
                                .font(.nohemiArabicBody)
                                .foregroundColor(.nawawi_headingText)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .lineSpacing(.lineSpacing_arabicCompact)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.nawawi_softCream)
                                )
                                .environment(\.layoutDirection, .rightToLeft)
                                .textSelection(.enabled)
                        }

                    // Translation
                    if appState.selectedLanguage != .arabic {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("English Translation")
                                .font(.caption)
                                .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))

                            Text(hadith.englishTranslation)
                                .font(.nohemiListTitle)
                                .foregroundColor(.nawawi_bodyText)
                                .lineSpacing(.lineSpacing_normal)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.nawawi_softCream)
                                )
                                .textSelection(.enabled)
                        }
                    }

                    // Additional info
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Narrator", systemImage: "person.circle")
                            .font(.caption)
                            .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))

                        Text(hadith.narrator)
                            .font(.body)
                            .foregroundColor(.black)
                            .padding(.leading, 24)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.nawawi_softCream)
                    )
                }
                .padding()
            }
            .frame(width: windowSize.width, height: windowSize.height - 80)
        }
    }
}

// MARK: - MenuBar Settings Wrapper
struct MenuBarSettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var notificationManager: NotificationManager
    @Binding var currentView: MenuBarView.ViewMode
    @Binding var windowSize: CGSize

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .foregroundColor(.black)
                    .font(.title2.bold())

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.4)) {
                        currentView = .main
                    }
                }) {
                    Label("Done", systemImage: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding()

            Divider()
                .opacity(0.3)

            // Use unified SettingsContentView
            SettingsContentView()
                .environmentObject(appState)
                .environmentObject(favoritesManager)
                .environmentObject(notificationManager)
                .frame(width: windowSize.width, height: windowSize.height - 80)
        }
    }
}

