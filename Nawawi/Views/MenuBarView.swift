//
//  MenuBarView.swift
//  Nawawi
//
//  Created by Khurshid Marazikov on 8/31/25.
//

import SwiftUI
import UserNotifications
import AppKit

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var dataManager = HadithDataManager.shared
    @State private var showFullHadith = false
    @State private var showSettings = false
    @State private var showingFavoritesOnly = false
    @State private var searchText = ""
    @State private var currentView: ViewMode = .main
    @State private var windowSize = CGSize(width: 450, height: 550)
    @State private var showExportMenu = false

    @FocusState private var isSearchFocused: Bool

    enum ViewMode {
        case main
        case settings
        case detail
    }

    var currentHadith: Hadith? {
        let displayHadiths = filteredHadiths
        guard !displayHadiths.isEmpty else {
            DispatchQueue.main.async {
                appState.currentHadithIndex = 0
            }
            return nil
        }
        let safeIndex = min(max(0, appState.currentHadithIndex), displayHadiths.count - 1)
        if safeIndex != appState.currentHadithIndex {
            DispatchQueue.main.async {
                appState.currentHadithIndex = safeIndex
            }
        }
        return displayHadiths[safeIndex]
    }

    var filteredHadiths: [Hadith] {
        dataManager.searchHadiths(
            query: searchText,
            language: appState.selectedLanguage,
            favoritesOnly: showingFavoritesOnly,
            favorites: appState.favorites
        )
    }

    var body: some View {
        ZStack {
            // Enhanced Liquid Glass background for macOS 26
            LiquidGlassBackground()

            switch currentView {
            case .settings:
                SettingsInlineView(currentView: $currentView, windowSize: $windowSize)
                    .environmentObject(appState)
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

                    // Loading or Error state
                    if dataManager.isLoading {
                        LoadingView()
                            .frame(width: windowSize.width, height: windowSize.height - 120)
                    } else if let error = dataManager.error {
                        ErrorView(error: error) {
                            dataManager.loadHadiths()
                        }
                        .frame(width: windowSize.width, height: windowSize.height - 120)
                    } else if let hadith = currentHadith {
                        // Main content with animation
                        ScrollView {
                            VStack(spacing: 20) {
                                // Progress indicator
                                HadithProgressIndicator(
                                    current: appState.currentHadithIndex + 1,
                                    total: filteredHadiths.count,
                                    selectedIndex: $appState.currentHadithIndex
                                )
                                .padding(.top)

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
                        .frame(width: windowSize.width, height: windowSize.height - 120)
                    } else {
                        ContentUnavailableView(
                            "No Hadiths",
                            systemImage: "book.closed",
                            description: Text(searchText.isEmpty ? "No hadiths available" : "No hadiths match your search")
                        )
                        .frame(width: windowSize.width, height: windowSize.height - 120)
                    }

                    Divider()
                        .opacity(0.3)

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
        }
        .onReceive(appState.$showSettings) { show in
            if show {
                currentView = .settings
            }
        }
    }

    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
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

// MARK: - Enhanced Header View
struct EnhancedHeaderView: View {
    @Binding var searchText: String
    var isSearchFocused: FocusState<Bool>.Binding
    @Binding var showingFavoritesOnly: Bool
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // App icon with animation
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolEffect(.pulse, isActive: appState.hasActiveReminder)

                Text("40 Hadith")
                    .font(.headline)
                    .fontWeight(.semibold)

                // Language selector with flags
                Menu {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Button(action: {
                            withAnimation {
                                appState.selectedLanguage = language
                            }
                        }) {
                            Label {
                                HStack {
                                    Text(language.displayName)
                                    if appState.selectedLanguage == language {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.green)
                                    }
                                }
                            } icon: {
                                Text(language.flag)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(appState.selectedLanguage.flag)
                            .font(.title3)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .menuStyle(.borderlessButton)

                Spacer()

                // Filter toggle
                Button(action: {
                    withAnimation {
                        showingFavoritesOnly.toggle()
                        appState.currentHadithIndex = 0
                    }
                }) {
                    Label("Favorites", systemImage: showingFavoritesOnly ? "heart.fill" : "heart")
                        .foregroundStyle(showingFavoritesOnly ? .red : .secondary)
                        .symbolEffect(.bounce, value: showingFavoritesOnly)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("l", modifiers: [.command])
            }

            // Enhanced search bar
            SearchBar(
                text: $searchText,
                isFocused: isSearchFocused,
                placeholder: "Search hadiths...",
                onClear: {
                    appState.currentHadithIndex = 0
                }
            )
            .keyboardShortcut("f", modifiers: [.command])
        }
        .padding()
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .padding(.horizontal)
        .padding(.top)
    }
}

// MARK: - Enhanced Hadith Card
struct EnhancedHadithCard: View {
    let hadith: Hadith
    let searchHighlight: String
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: HadithDataManager
    @State private var isHovered = false
    @State private var isFavoriteAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with animation
            HStack {
                Label {
                    Text("Hadith #\(hadith.number)")
                        .font(.caption)
                        .fontWeight(.medium)
                } icon: {
                    Image(systemName: "number.circle.fill")
                        .font(.caption)
                        .symbolRenderingMode(.hierarchical)
                }
                .foregroundStyle(.secondary)

                Spacer()

                // Export button
                Menu {
                    Button(action: { copyToClipboard(.plain) }) {
                        Label("Copy as Plain Text", systemImage: "doc.on.doc")
                    }
                    Button(action: { copyToClipboard(.markdown) }) {
                        Label("Copy as Markdown", systemImage: "text.badge.checkmark")
                    }
                    Button(action: { shareHadith() }) {
                        Label("Share...", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)

                // Favorite button with enhanced animation
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        appState.toggleFavorite(hadith.number)
                        isFavoriteAnimating = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isFavoriteAnimating = false
                    }
                }) {
                    Image(systemName: appState.favorites.contains(hadith.number) ? "heart.fill" : "heart")
                        .foregroundStyle(appState.favorites.contains(hadith.number) ? .red : .secondary)
                        .symbolEffect(.bounce, value: appState.favorites.contains(hadith.number))
                        .scaleEffect(isFavoriteAnimating ? 1.2 : 1.0)
                }
                .buttonStyle(.plain)
            }

            // Arabic text with glass background
            if appState.selectedLanguage == .arabic || appState.selectedLanguage == .english {
                VStack(alignment: .trailing, spacing: 8) {
                    if !searchHighlight.isEmpty && hadith.arabicText.contains(searchHighlight) {
                        HighlightedText(hadith.arabicText, highlight: searchHighlight, font: .system(size: 20))
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .environment(\.layoutDirection, .rightToLeft)
                    } else {
                        Text(hadith.arabicText)
                            .font(.system(size: 20))
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .environment(\.layoutDirection, .rightToLeft)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
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
            }

            // Translation with highlighting
            Group {
                switch appState.selectedLanguage {
                case .arabic:
                    EmptyView()
                case .english:
                    if !searchHighlight.isEmpty && hadith.englishTranslation.localizedCaseInsensitiveContains(searchHighlight) {
                        HighlightedText(hadith.englishTranslation, highlight: searchHighlight, font: .system(size: 14))
                            .foregroundStyle(.primary)
                            .lineSpacing(4)
                    } else {
                        Text(hadith.englishTranslation)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                            .lineSpacing(4)
                    }
                case .uzbek:
                    if let uzbekTranslation = hadith.uzbekTranslation {
                        if !searchHighlight.isEmpty && uzbekTranslation.localizedCaseInsensitiveContains(searchHighlight) {
                            HighlightedText(uzbekTranslation, highlight: searchHighlight, font: .system(size: 14))
                                .foregroundStyle(.primary)
                                .lineSpacing(4)
                        } else {
                            Text(uzbekTranslation)
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                                .lineSpacing(4)
                        }
                    }
                }
            }

            // Narrator with icon
            Label {
                if !searchHighlight.isEmpty && hadith.narrator.localizedCaseInsensitiveContains(searchHighlight) {
                    HighlightedText(hadith.narrator, highlight: searchHighlight, font: .caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(hadith.narrator)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "person.circle.fill")
                    .font(.caption)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: isHovered ? 8 : 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(isHovered ? 0.4 : 0.2), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3)) {
                isHovered = hovering
            }
        }
    }

    private func copyToClipboard(_ format: ExportFormat) {
        let text = dataManager.exportHadith(hadith, format: format)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func shareHadith() {
        let text = dataManager.exportHadith(hadith, format: .plain)
        let sharingPicker = NSSharingServicePicker(items: [text])
        sharingPicker.show(relativeTo: .zero, of: NSApp.keyWindow?.contentView ?? NSView(), preferredEdge: .minY)
    }
}

// MARK: - Enhanced Toolbar
struct EnhancedToolbarView: View {
    @Binding var showingFavoritesOnly: Bool
    @Binding var showSettings: Bool
    let filteredCount: Int
    @Binding var currentView: MenuBarView.ViewMode
    @EnvironmentObject var appState: AppState
    let navigateNext: () -> Void
    let navigatePrevious: () -> Void
    let onRandomHadith: () -> Void
    let onExport: () -> Void

    var body: some View {
        HStack {
            // Navigation group
            HStack(spacing: 12) {
                Button(action: navigatePrevious) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                .disabled(filteredCount == 0)
                .keyboardShortcut(.leftArrow, modifiers: [.command])

                Text("\(filteredCount > 0 ? appState.currentHadithIndex + 1 : 0) / \(filteredCount)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(minWidth: 50)

                Button(action: navigateNext) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
                .disabled(filteredCount == 0)
                .keyboardShortcut(.rightArrow, modifiers: [.command])
            }

            Spacer()

            // Action buttons
            HStack(spacing: 16) {
                Button(action: onRandomHadith) {
                    Image(systemName: "shuffle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Random Hadith (⌘R)")
                .keyboardShortcut("r", modifiers: [.command])

                Button(action: onExport) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Export")

                Button(action: { currentView = .settings }) {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Settings")
                .keyboardShortcut(",", modifiers: [.command])

                Divider()
                    .frame(height: 20)

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Quit (⌘Q)")
                .keyboardShortcut("q", modifiers: [.command])
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.circle")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.accentColor, .accentColor.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)

            Text("Loading Hadiths...")
                .font(.headline)
                .foregroundStyle(.secondary)

            ProgressView()
                .progressViewStyle(.linear)
                .frame(width: 200)
        }
        .padding(40)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let error: Error
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
                .symbolEffect(.bounce)

            Text("Unable to Load Hadiths")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }
}

// MARK: - Liquid Glass Background
struct LiquidGlassBackground: View {
    var body: some View {
        ZStack {
            // Base layer
            Rectangle()
                .fill(.ultraThinMaterial)

            // Gradient overlay for depth
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .accentColor.opacity(0.02), location: 0.5),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Animated gradient for liquid effect
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate

                RadialGradient(
                    colors: [
                        .accentColor.opacity(0.03),
                        .clear
                    ],
                    center: UnitPoint(
                        x: 0.5 + 0.3 * sin(time * 0.5),
                        y: 0.5 + 0.3 * cos(time * 0.3)
                    ),
                    startRadius: 50,
                    endRadius: 200
                )
                .blur(radius: 20)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Enhanced Detail View
struct HadithDetailInlineView: View {
    let hadith: Hadith
    @Binding var currentView: MenuBarView.ViewMode
    @Binding var windowSize: CGSize
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: HadithDataManager
    @State private var copiedToClipboard = false
    @State private var selectedExportFormat: ExportFormat = .plain

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hadith #\(hadith.number)")
                        .font(.title2.bold())

                    Label(hadith.narrator, systemImage: "person.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 16) {
                    // Favorite button
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            appState.toggleFavorite(hadith.number)
                        }
                    }) {
                        Image(systemName: appState.favorites.contains(hadith.number) ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundStyle(appState.favorites.contains(hadith.number) ? .red : .secondary)
                            .symbolEffect(.bounce, value: appState.favorites.contains(hadith.number))
                    }
                    .buttonStyle(.plain)

                    // Export menu
                    Menu {
                        Button(action: { exportHadith(.plain) }) {
                            Label("Export as Text", systemImage: "doc.text")
                        }
                        Button(action: { exportHadith(.markdown) }) {
                            Label("Export as Markdown", systemImage: "text.badge.checkmark")
                        }
                        Button(action: { exportHadith(.json) }) {
                            Label("Export as JSON", systemImage: "curlybraces")
                        }
                        Divider()
                        Button(action: shareHadith) {
                            Label("Share...", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: copiedToClipboard ? "checkmark.circle.fill" : "square.and.arrow.up")
                            .font(.title3)
                            .foregroundStyle(copiedToClipboard ? .green : .secondary)
                            .symbolEffect(.bounce, value: copiedToClipboard)
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
                            .foregroundStyle(.secondary)
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
                                Text(language.displayName)
                            }
                            .tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Arabic text
                    if appState.selectedLanguage == .arabic || appState.selectedLanguage == .english {
                        VStack(alignment: .trailing, spacing: 10) {
                            HStack {
                                Text("Arabic Text")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button(action: { speakText(hadith.arabicText, language: "ar-SA") }) {
                                    Image(systemName: "speaker.wave.2")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }

                            Text(hadith.arabicText)
                                .font(.system(size: 20))
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .lineSpacing(8)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                                .environment(\.layoutDirection, .rightToLeft)
                        }
                    }

                    // Translation
                    if appState.selectedLanguage != .arabic {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(appState.selectedLanguage == .uzbek ? "O'zbek tarjimasi" : "English Translation")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button(action: {
                                    let text = appState.selectedLanguage == .uzbek ?
                                        (hadith.uzbekTranslation ?? hadith.englishTranslation) :
                                        hadith.englishTranslation
                                    let lang = appState.selectedLanguage == .uzbek ? "uz" : "en-US"
                                    speakText(text, language: lang)
                                }) {
                                    Image(systemName: "speaker.wave.2")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }

                            if appState.selectedLanguage == .uzbek {
                                Text(hadith.uzbekTranslation ?? hadith.englishTranslation)
                                    .font(.system(size: 15))
                                    .lineSpacing(6)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                    )
                            } else {
                                Text(hadith.englishTranslation)
                                    .font(.system(size: 15))
                                    .lineSpacing(6)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                        }
                    }

                    // Additional info
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Narrator", systemImage: "person.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(hadith.narrator)
                            .font(.body)
                            .padding(.leading, 24)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
                .padding()
            }
            .frame(width: windowSize.width, height: windowSize.height - 80)
        }
    }

    private func exportHadith(_ format: ExportFormat) {
        let text = dataManager.exportHadith(hadith, format: format)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        withAnimation {
            copiedToClipboard = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copiedToClipboard = false
            }
        }
    }

    private func shareHadith() {
        let text = dataManager.exportHadith(hadith, format: .plain)
        let sharingPicker = NSSharingServicePicker(items: [text])
        sharingPicker.show(relativeTo: .zero, of: NSApp.keyWindow?.contentView ?? NSView(), preferredEdge: .minY)
    }

    private func speakText(_ text: String, language: String) {
        let synthesizer = NSSpeechSynthesizer()
        synthesizer.setVoice(NSSpeechSynthesizer.VoiceName(rawValue: "com.apple.speech.synthesis.voice.\(language)"))
        synthesizer.startSpeaking(text)
    }
}

// MARK: - Enhanced Settings View
struct SettingsInlineView: View {
    @EnvironmentObject var appState: AppState
    @Binding var currentView: MenuBarView.ViewMode
    @Binding var windowSize: CGSize
    @State private var selectedTime = Date()
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingPermissionAlert = false
    @State private var showingAbout = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
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

            ScrollView {
                VStack(spacing: 20) {
                    // Window Size Settings
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Window Size", systemImage: "macwindow")
                                .font(.headline)

                            Slider(value: $windowSize.width, in: 380...600, step: 10) {
                                Text("Width")
                            }
                            Text("Width: \(Int(windowSize.width))px")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Slider(value: $windowSize.height, in: 450...700, step: 10) {
                                Text("Height")
                            }
                            Text("Height: \(Int(windowSize.height))px")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Notifications Section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Notifications", systemImage: "bell")
                                .font(.headline)

                            if permissionStatus == .denied {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.yellow)
                                    Text("Notifications are disabled in System Settings")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Button("Open System Settings") {
                                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                                .buttonStyle(.link)
                            } else if permissionStatus == .notDetermined {
                                Button("Enable Notifications") {
                                    appState.requestNotificationPermission { granted in
                                        checkPermissionStatus()
                                        if granted {
                                            appState.reminderEnabled = true
                                            appState.scheduleReminder()
                                        }
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }

                            Toggle("Daily Reminder", isOn: $appState.reminderEnabled)
                                .disabled(permissionStatus != .authorized)
                                .onChange(of: appState.reminderEnabled) { _, enabled in
                                    if enabled {
                                        appState.scheduleReminder()
                                    } else {
                                        appState.cancelReminder()
                                    }
                                }

                            if appState.reminderEnabled && permissionStatus == .authorized {
                                DatePicker("Reminder Time",
                                          selection: $selectedTime,
                                          displayedComponents: .hourAndMinute)
                                    .onChange(of: selectedTime) { _, newTime in
                                        let components = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                                        appState.reminderHour = components.hour ?? 9
                                        appState.reminderMinute = components.minute ?? 0
                                        appState.scheduleReminder()
                                    }

                                Button("Send Test Notification") {
                                    appState.sendTestNotification()
                                }
                                .buttonStyle(.link)
                            }
                        }
                    }

                    // Favorites Section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Favorites", systemImage: "heart")
                                .font(.headline)

                            if appState.favorites.isEmpty {
                                Text("No favorites yet")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(appState.favorites.count) hadith\(appState.favorites.count == 1 ? "" : "s") marked as favorite")

                                Button("Clear All Favorites") {
                                    appState.favorites.removeAll()
                                    appState.saveFavorites()
                                }
                                .foregroundStyle(.red)
                            }
                        }
                    }

                    // Keyboard Shortcuts
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Keyboard Shortcuts", systemImage: "keyboard")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 8) {
                                ShortcutRow(keys: "⌘ ←/→", action: "Navigate hadiths")
                                ShortcutRow(keys: "⌘ F", action: "Focus search")
                                ShortcutRow(keys: "⌘ L", action: "Toggle favorites")
                                ShortcutRow(keys: "⌘ R", action: "Random hadith")
                                ShortcutRow(keys: "⌘ ,", action: "Settings")
                                ShortcutRow(keys: "⌘ Q", action: "Quit app")
                                ShortcutRow(keys: "ESC", action: "Go back")
                            }
                        }
                    }

                    // About Section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("About", systemImage: "info.circle")
                                .font(.headline)

                            Text("40 Hadith Nawawi")
                                .font(.body)
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("A collection of forty hadiths compiled by Imam Nawawi")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .frame(width: windowSize.width, height: windowSize.height - 80)
        }
        .onAppear {
            var components = DateComponents()
            components.hour = appState.reminderHour
            components.minute = appState.reminderMinute
            selectedTime = Calendar.current.date(from: components) ?? Date()

            checkPermissionStatus()
        }
    }

    private func checkPermissionStatus() {
        appState.checkNotificationPermission { status in
            permissionStatus = status
        }
    }
}

// MARK: - Shortcut Row
struct ShortcutRow: View {
    let keys: String
    let action: String

    var body: some View {
        HStack {
            Text(keys)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.quaternary)
                )

            Text(action)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

// MARK: - Hadith Model
struct Hadith: Codable, Identifiable {
    let number: Int
    let arabicText: String
    let englishTranslation: String
    let uzbekTranslation: String?
    let narrator: String

    var id: Int { number }
}
