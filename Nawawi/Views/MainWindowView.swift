//
//  MainWindowView.swift
//  Nawawi
//
//  Standalone window interface optimized for extended hadith study
//

import SwiftUI
import AppKit

struct MainWindowView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var dataManager = HadithDataManager.shared
    @State private var searchText = ""
    @State private var showingFavoritesOnly = false
    @State private var selectedHadithIndex: Int? = nil
    @State private var showSettings = false

    @FocusState private var isSearchFocused: Bool

    var filteredHadiths: [Hadith] {
        dataManager.searchHadiths(
            query: searchText,
            language: appState.selectedLanguage,
            favoritesOnly: showingFavoritesOnly,
            favorites: appState.favorites
        )
    }

    var currentHadith: Hadith? {
        guard !filteredHadiths.isEmpty else { return nil }
        let safeIndex = min(max(0, selectedHadithIndex ?? appState.currentHadithIndex), filteredHadiths.count - 1)
        return filteredHadiths[safeIndex]
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar with hadith list
            VStack(spacing: 0) {
                // Search and filters
                VStack(spacing: 12) {
                    SearchBar(
                        text: $searchText,
                        isFocused: $isSearchFocused,
                        placeholder: "Search hadiths...",
                        onClear: {
                            selectedHadithIndex = 0
                        }
                    )
                    .keyboardShortcut("f", modifiers: [.command])

                    HStack {
                        // Language selector
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
                                                .font(.nohemiCaption)
                                                .foregroundColor(.black)
                                            if appState.selectedLanguage == language {
                                                Image(systemName: "checkmark")
                                                    .foregroundStyle(.green)
                                            }
                                        }
                                    } icon: {
                                        Text(language.flag)
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(appState.selectedLanguage.flag)
                                    .font(.title3)
                                    .foregroundColor(.black)
                                Text(appState.selectedLanguage.displayName)
                                    .font(.nohemiCaption)
                                    .foregroundColor(.black)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .menuStyle(.borderlessButton)

                        Spacer()

                        // Favorites filter
                        Button(action: {
                            withAnimation {
                                showingFavoritesOnly.toggle()
                                selectedHadithIndex = 0
                            }
                        }) {
                            Label("Favorites", systemImage: showingFavoritesOnly ? "heart.fill" : "heart")
                                .font(.nohemiButton)
                                .foregroundStyle(showingFavoritesOnly ? Color.nawawi_darkGreen : .black)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut("l", modifiers: [.command])
                    }
                }
                .padding()
                .background(Color.nawawi_softCream)

                Divider()

                // Hadith list
                if dataManager.isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("Loading Hadiths...")
                            .font(.nohemiBody)
                            .foregroundColor(.black)
                    }
                    Spacer()
                } else if let error = dataManager.error {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundStyle(.orange)
                        Text("Unable to Load Hadiths")
                            .font(.nohemiHeadline)
                            .foregroundColor(.black)
                        Text(error.localizedDescription)
                            .font(.nohemiCaption)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            dataManager.loadHadiths()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    Spacer()
                } else {
                    List(filteredHadiths.indices, id: \.self, selection: $selectedHadithIndex) { index in
                        HadithListRow(
                            hadith: filteredHadiths[index],
                            isSelected: selectedHadithIndex == index,
                            isFavorite: appState.favorites.contains(filteredHadiths[index].number),
                            searchHighlight: searchText
                        ) {
                            appState.toggleFavorite(filteredHadiths[index].number)
                        }
                        .tag(index)
                    }
                    .listStyle(.sidebar)
                }
            }
        } detail: {
            // Main content area
            if let hadith = currentHadith {
                HadithDetailView(hadith: hadith)
                    .environmentObject(appState)
                    .environmentObject(dataManager)
            } else {
                ContentUnavailableView(
                    "Select a Hadith",
                    systemImage: "book.closed",
                    description: Text("Choose a hadith from the sidebar to read")
                        .foregroundColor(.black)
                )
            }
        }
        .navigationSplitViewColumnWidth(min: 300, ideal: 350, max: 400)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: {
                    showSettings.toggle()
                }) {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.gray)
                }
                .help("Settings")
                .keyboardShortcut(",", modifiers: [.command])
            }
        }
        .onAppear {
            // Sync with app state
            if selectedHadithIndex == nil && !filteredHadiths.isEmpty {
                let safeIndex = min(max(0, appState.currentHadithIndex), filteredHadiths.count - 1)
                selectedHadithIndex = safeIndex
            }
        }
        .onChange(of: selectedHadithIndex) { _, newIndex in
            if let index = newIndex, index < filteredHadiths.count {
                appState.currentHadithIndex = index
                appState.saveCurrentIndex()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsWindowView()
                .environmentObject(appState)
        }
    }
}

// MARK: - Hadith List Row
struct HadithListRow: View {
    let hadith: Hadith
    let isSelected: Bool
    let isFavorite: Bool
    let searchHighlight: String
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Hadith #\(hadith.number)")
                        .font(.nohemiButton)
                        .foregroundColor(isSelected ? .white : .black)

                    Spacer()

                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(isFavorite ? .red : (isSelected ? .white : .gray))
                    }
                    .buttonStyle(.plain)
                }

                if !searchHighlight.isEmpty && hadith.englishTranslation.localizedCaseInsensitiveContains(searchHighlight) {
                    HighlightedText(
                        hadith.englishTranslation,
                        highlight: searchHighlight,
                        font: .caption
                    )
                    .foregroundColor(isSelected ? .white : .black)
                    .lineLimit(3)
                } else {
                    Text(hadith.englishTranslation)
                        .font(.nohemiCaptionLight)
                        .foregroundColor(isSelected ? .white : .black)
                        .lineLimit(3)
                }

                Text(hadith.narrator)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .gray)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.nawawi_darkGreen : Color.clear)
        )
    }
}

// MARK: - Hadith Detail View
struct HadithDetailView: View {
    let hadith: Hadith
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: HadithDataManager
    @State private var copiedToClipboard = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hadith #\(hadith.number)")
                            .font(.nohemiTitle)
                            .foregroundColor(.black)

                        Label(hadith.narrator, systemImage: "person.circle.fill")
                            .font(.nohemiCaption)
                            .foregroundStyle(.gray)
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
                                .font(.title2)
                                .foregroundStyle(appState.favorites.contains(hadith.number) ? .red : .gray)
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
                                .font(.title2)
                                .foregroundStyle(copiedToClipboard ? .green : .gray)
                                .symbolEffect(.bounce, value: copiedToClipboard)
                        }
                        .menuStyle(.borderlessButton)
                    }
                }

                // Arabic text
                if appState.selectedLanguage == .arabic || appState.selectedLanguage == .english {
                    VStack(alignment: .trailing, spacing: 12) {
                        HStack {
                            Text("Arabic Text")
                                .font(.nohemiCaption)
                                .foregroundColor(.black)
                            Spacer()
                            Button(action: { speakText(hadith.arabicText, language: "ar-SA") }) {
                                Image(systemName: "speaker.wave.2")
                                    .foregroundStyle(.gray)
                            }
                            .buttonStyle(.plain)
                        }

                        Text(hadith.arabicText)
                            .font(.system(size: 24, weight: .regular, design: .default))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .lineSpacing(10)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.nawawi_softCream)
                            )
                            .environment(\.layoutDirection, .rightToLeft)
                    }
                }

                // Translation
                if appState.selectedLanguage != .arabic {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(appState.selectedLanguage == .uzbek ? "O'zbek tarjimasi" : "English Translation")
                                .font(.nohemiCaption)
                                .foregroundColor(.black)
                            Spacer()
                            Button(action: {
                                let text = appState.selectedLanguage == .uzbek ?
                                    (hadith.uzbekTranslation ?? hadith.englishTranslation) :
                                    hadith.englishTranslation
                                let lang = appState.selectedLanguage == .uzbek ? "uz" : "en-US"
                                speakText(text, language: lang)
                            }) {
                                Image(systemName: "speaker.wave.2")
                                    .foregroundStyle(.gray)
                            }
                            .buttonStyle(.plain)
                        }

                        Text(appState.selectedLanguage == .uzbek ?
                             (hadith.uzbekTranslation ?? hadith.englishTranslation) :
                             hadith.englishTranslation)
                            .font(.nohemiBody)
                            .foregroundColor(.black)
                            .lineSpacing(8)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.nawawi_softCream)
                            )
                    }
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.nawawi_background)
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

// MARK: - Settings Window View
struct SettingsWindowView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.nohemiTitle)
                    .foregroundColor(.black)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Notifications Section - reuse from MenuBarView settings
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Notifications", systemImage: "bell")
                                .font(.nohemiHeadline)
                                .foregroundColor(.black)

                            Toggle("Daily Reminder", isOn: $appState.reminderEnabled)
                                .onChange(of: appState.reminderEnabled) { _, enabled in
                                    if enabled {
                                        appState.scheduleReminder()
                                    } else {
                                        appState.cancelReminder()
                                    }
                                }
                        }
                    }

                    // Favorites Section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Favorites", systemImage: "heart")
                                .font(.nohemiHeadline)
                                .foregroundColor(.black)

                            if appState.favorites.isEmpty {
                                Text("No favorites yet")
                                    .foregroundColor(.gray)
                            } else {
                                Text("\(appState.favorites.count) hadith\(appState.favorites.count == 1 ? "" : "s") marked as favorite")
                                    .foregroundColor(.black)

                                Button(action: {
                                    appState.favorites.removeAll()
                                    appState.saveFavorites()
                                }) {
                                    Text("Clear All Favorites")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }

                    // About Section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("About", systemImage: "info.circle")
                                .font(.nohemiHeadline)
                                .foregroundColor(.black)

                            Text("40 Hadith Nawawi")
                                .font(.nohemiBody)
                                .foregroundColor(.black)
                            Text("Version 1.0.0")
                                .font(.nohemiCaption)
                                .foregroundColor(.black)
                            Text("A collection of forty hadiths compiled by Imam Nawawi")
                                .font(.nohemiCaption)
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 500, height: 400)
        .background(Color.nawawi_background)
    }
}