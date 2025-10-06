//
//  MainWindowView.swift
//  Nawawi
//
//  Standalone window interface optimized for extended hadith study
//

import SwiftUI
import AppKit
import UserNotifications
import Sparkle

struct MainWindowView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: HadithDataManager
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var hadithActionService: HadithActionService
    @EnvironmentObject var speechService: SpeechService
    @State private var searchText = ""
    @State private var showingFavoritesOnly = false
    @State private var selectedHadithIndex: Int? = nil
    @State private var showSettings = false
    @State private var showChapterNavigator = false
    @State private var filterByChapterId: Int? = nil

    @FocusState private var isSearchFocused: Bool

    var filteredHadiths: [Hadith] {
        var hadiths = dataManager.searchHadiths(
            query: searchText,
            language: appState.selectedLanguage,
            favoritesOnly: showingFavoritesOnly,
            favorites: favoritesManager.favorites
        )

        // Apply chapter filter if active
        if let chapterId = filterByChapterId {
            hadiths = hadiths.filter { $0.chapterId == chapterId }
        }

        return hadiths
    }

    var currentHadith: Hadith? {
        guard !filteredHadiths.isEmpty else { return nil }
        let safeIndex = min(max(0, selectedHadithIndex ?? appState.currentHadithIndex), filteredHadiths.count - 1)
        return filteredHadiths[safeIndex]
    }

    var body: some View {
        HStack(spacing: 0) {
            // Chapter Navigator Sidebar (optional)
            if showChapterNavigator {
                ChapterNavigator(
                    isVisible: $showChapterNavigator,
                    selectedHadithIndex: $selectedHadithIndex,
                    filterByChapterId: $filterByChapterId,
                    filteredHadiths: filteredHadiths,
                    onChapterSelected: {
                        // Clear search text when chapter is selected
                        searchText = ""
                    }
                )
                    .environmentObject(dataManager)
                    .environmentObject(appState)
                    .transition(.move(edge: .leading))
            }

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
                        // Book selector
                        BookSelectorMenu(
                            selectedIndex: $selectedHadithIndex,
                            onBookChange: {
                                // Clear all filters when book changes
                                filterByChapterId = nil
                                searchText = ""
                                showingFavoritesOnly = false
                            }
                        )

                        Divider()
                            .frame(height: 20)

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

                // Chapter filter indicator (if active)
                if filterByChapterId != nil,
                   let firstHadith = filteredHadiths.first,
                   let chapter = firstHadith.chapter {
                    HStack(spacing: 8) {
                        Image(systemName: "book.pages.fill")
                            .foregroundStyle(Color.nawawi_darkGreen)
                        Text("Chapter \(chapter.id): \(chapter.title)")
                            .font(.nohemiCaption)
                            .foregroundColor(.black)
                        Spacer()
                        Button(action: {
                            withAnimation {
                                filterByChapterId = nil
                                selectedHadithIndex = 0
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Show all hadiths")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.nawawi_lightGreen.opacity(0.2))

                    Divider()
                }

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
                            isFavorite: favoritesManager.isFavorite(filteredHadiths[index].number),
                            searchHighlight: searchText
                        ) {
                            favoritesManager.toggleFavorite(filteredHadiths[index].number)
                        }
                        .tag(index)
                    }
                    .listStyle(.sidebar)
                }
            }
        } detail: {
            // Main content area
            if let hadith = currentHadith {
                HadithDetailView(
                    hadith: hadith,
                    filteredHadiths: filteredHadiths,
                    selectedHadithIndex: $selectedHadithIndex
                )
                    .environmentObject(appState)
                    .environmentObject(dataManager)
                    .environmentObject(favoritesManager)
                    .environmentObject(notificationManager)
            } else {
                ContentUnavailableView(
                    "Select a Hadith",
                    systemImage: "book.closed",
                    description: Text("Choose a hadith from the sidebar to read")
                        .foregroundColor(.black)
                )
            }
        }
        .navigationSplitViewColumnWidth(min: 500, ideal: 580, max: 700)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: {
                    withAnimation {
                        showChapterNavigator.toggle()
                    }
                }) {
                    Image(systemName: "sidebar.left")
                        .foregroundStyle(showChapterNavigator ? Color.nawawi_darkGreen : .gray)
                }
                .help("Toggle Chapters")
                .keyboardShortcut("k", modifiers: [.command])

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

            // Check for pending hadith navigation from notification
            if let pending = appState.pendingHadithNavigation {
                print("📍 MainWindowView: Navigating to pending hadith \(pending)")
                selectedHadithIndex = pending
                appState.currentHadithIndex = pending
                appState.pendingHadithNavigation = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenHadith"))) { notification in
            if let hadithIndex = notification.userInfo?["hadithIndex"] as? Int {
                print("📍 MainWindowView: Received OpenHadith notification for index \(hadithIndex)")

                // Clear all filters to ensure the hadith is visible
                withAnimation {
                    filterByChapterId = nil
                    searchText = ""
                    showingFavoritesOnly = false

                    // Set the hadith index
                    appState.currentHadithIndex = hadithIndex

                    // Find the hadith in the now-unfiltered list
                    if hadithIndex < dataManager.hadiths.count {
                        let targetHadith = dataManager.hadiths[hadithIndex]
                        if let filteredIndex = filteredHadiths.firstIndex(where: { $0.number == targetHadith.number }) {
                            selectedHadithIndex = filteredIndex
                        }
                    }
                }
            }
        }
        .onChange(of: selectedHadithIndex) { _, newIndex in
            if let index = newIndex, index < filteredHadiths.count {
                // Update appState.currentHadithIndex to match the actual hadith number
                // Find the hadith in the full list by number
                let selectedHadith = filteredHadiths[index]
                if let indexInFullList = dataManager.hadiths.firstIndex(where: { $0.number == selectedHadith.number }) {
                    appState.currentHadithIndex = indexInFullList
                    appState.saveCurrentIndex()
                }
            }
        }
        .onChange(of: appState.currentHadithIndex) { _, newIndex in
            // Sync selectedHadithIndex when appState.currentHadithIndex changes externally
            guard newIndex < dataManager.hadiths.count else { return }
            let currentHadith = dataManager.hadiths[newIndex]
            if let indexInFilteredList = filteredHadiths.firstIndex(where: { $0.number == currentHadith.number }) {
                if selectedHadithIndex != indexInFilteredList {
                    selectedHadithIndex = indexInFilteredList
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsWindowView()
                .environmentObject(appState)
                .environmentObject(favoritesManager)
                .environmentObject(notificationManager)
        }
        } // Close HStack
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
    let filteredHadiths: [Hadith]
    @Binding var selectedHadithIndex: Int?
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: HadithDataManager
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var hadithActionService: HadithActionService

    var body: some View {
        VStack(spacing: 0) {
            // Main scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Book metadata banner (if available)
                if let book = hadith.book {
                    HStack(spacing: 12) {
                        Image(systemName: dataManager.currentBook.icon)
                            .font(.title2)
                            .foregroundStyle(Color.nawawi_darkGreen)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.nohemiBody)
                                .foregroundColor(.black)
                            Text(book.arabicTitle)
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(hadith.idInBook ?? hadith.number)/\(book.totalHadiths)")
                                .font(.caption)
                                .foregroundStyle(.gray)

                            // Show sunnah.com reference if book has offset
                            if let sunnahRef = dataManager.currentBook.sunnahComReference(for: hadith.number),
                               sunnahRef != hadith.number {
                                Text("sunnah.com #\(sunnahRef)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            // Show numbering note if applicable
                            if let note = dataManager.currentBook.numberingNote {
                                Text(note)
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: 200)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.nawawi_softCream)
                        )
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.nawawi_softCream.opacity(0.5))
                    )
                }

                // Chapter banner (if available)
                if let chapter = hadith.chapter {
                    HStack(spacing: 12) {
                        // Chapter icon
                        Image(systemName: "book.pages.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.nawawi_darkGreen, Color.nawawi_lightGreen],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(alignment: .leading, spacing: 6) {
                            // Chapter title
                            Text(chapter.title)
                                .font(.nohemiHeadline)
                                .foregroundColor(.black)

                            // Arabic chapter title
                            Text(chapter.arabicTitle)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)

                            // Position in chapter
                            if let chapterId = hadith.chapterId {
                                let hadiths = dataManager.hadiths.filter { $0.chapterId == chapterId }
                                let positionInChapter = hadiths.firstIndex(where: { $0.number == hadith.number }).map { $0 + 1 } ?? 0

                                Text("Hadith \(positionInChapter) of \(hadiths.count) in this chapter")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        // Chapter ID badge
                        Text("Ch \(chapter.id)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.nawawi_darkGreen)
                            )
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.nawawi_softCream.opacity(0.8),
                                        Color.nawawi_lightGreen.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.nawawi_darkGreen.opacity(0.2), lineWidth: 1)
                    )
                }

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hadith #\(hadith.number)")
                            .font(.nohemiTitle)
                            .foregroundColor(.black)

                        // Enhanced narrator display
                        if !hadith.narrator.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.nawawi_darkGreen)

                                Text(hadith.narrator)
                                    .font(.nohemiBody)
                                    .foregroundStyle(.primary)
                            }
                        }
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
                                .font(.title2)
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
                                .font(.title2)
                                .foregroundStyle(hadithActionService.copiedToClipboard ? .green : .gray)
                                .symbolEffect(.bounce, value: hadithActionService.copiedToClipboard)
                        }
                        .menuStyle(.borderlessButton)
                    }
                }

                // Arabic text (always shown first according to Islamic practice)
                VStack(alignment: .trailing, spacing: 12) {
                    Text("Arabic Text")
                        .font(.nohemiCaption)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)

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
                        .textSelection(.enabled)
                }


                // Translation
                if appState.selectedLanguage != .arabic {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("English Translation")
                            .font(.nohemiCaption)
                            .foregroundColor(.black)

                        Text(hadith.englishTranslation)
                            .font(.nohemiBody)
                            .foregroundColor(.black)
                            .lineSpacing(8)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.nawawi_softCream)
                            )
                            .textSelection(.enabled)
                    }
                }
            }
            .padding(32)
            }

            // Fixed bottom chapter navigation bar (if chapter available)
            if let chapter = hadith.chapter, let chapterId = hadith.chapterId {
                // Get hadiths in this chapter from the FULL list (not filtered list)
                let chapHadiths = dataManager.hadiths.filter { $0.chapterId == chapterId }
                let currentIndex = chapHadiths.firstIndex(where: { $0.number == hadith.number }) ?? 0

                VStack(spacing: 0) {
                    Divider()

                    HStack(spacing: 16) {
                        // Previous in chapter button
                        Button(action: {
                            if currentIndex > 0 {
                                let prevHadith = chapHadiths[currentIndex - 1]
                                // Find in full list
                                if let fullListIndex = dataManager.hadiths.firstIndex(where: { $0.number == prevHadith.number }) {
                                    // Find in filtered list
                                    if let filteredListIndex = filteredHadiths.firstIndex(where: { $0.number == prevHadith.number }) {
                                        withAnimation {
                                            selectedHadithIndex = filteredListIndex
                                            appState.currentHadithIndex = fullListIndex
                                        }
                                    }
                                }
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.title2)
                                Text("Previous")
                                    .font(.nohemiButton)
                            }
                            .foregroundStyle(currentIndex > 0 ? Color.nawawi_darkGreen : .gray)
                        }
                        .buttonStyle(.plain)
                        .disabled(currentIndex == 0)
                        .help("Previous hadith in chapter")

                        Spacer()

                        // Chapter info in center
                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "book.pages.fill")
                                    .foregroundStyle(Color.nawawi_darkGreen)
                                Text("Ch \(chapter.id):")
                                    .fontWeight(.semibold)
                                Text(chapter.title)
                            }
                            .font(.nohemiBody)
                            .foregroundColor(.black)

                            Text("Hadith \(currentIndex + 1) of \(chapHadiths.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Next in chapter button
                        Button(action: {
                            if currentIndex < chapHadiths.count - 1 {
                                let nextHadith = chapHadiths[currentIndex + 1]
                                // Find in full list
                                if let fullListIndex = dataManager.hadiths.firstIndex(where: { $0.number == nextHadith.number }) {
                                    // Find in filtered list
                                    if let filteredListIndex = filteredHadiths.firstIndex(where: { $0.number == nextHadith.number }) {
                                        withAnimation {
                                            selectedHadithIndex = filteredListIndex
                                            appState.currentHadithIndex = fullListIndex
                                        }
                                    }
                                }
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text("Next")
                                    .font(.nohemiButton)
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.title2)
                            }
                            .foregroundStyle(currentIndex < chapHadiths.count - 1 ? Color.nawawi_darkGreen : .gray)
                        }
                        .buttonStyle(.plain)
                        .disabled(currentIndex >= chapHadiths.count - 1)
                        .help("Next hadith in chapter")
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.nawawi_softCream.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.nawawi_background)
    }
}

// MARK: - Settings Window View
struct SettingsWindowView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var notificationManager: NotificationManager
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

            // Use unified settings content
            SettingsContentView()
                .environmentObject(appState)
                .environmentObject(favoritesManager)
                .environmentObject(notificationManager)
        }
        .frame(width: 500, height: 600)
        .background(Color.nawawi_background)
    }
}

// MARK: - Book Selector Menu
struct BookSelectorMenu: View {
    @EnvironmentObject var dataManager: HadithDataManager
    @Binding var selectedIndex: Int?
    let onBookChange: () -> Void

    var body: some View {
        Menu {
            ForEach(HadithBook.allCases) { book in
                Button(action: {
                    withAnimation {
                        // Clear filters before changing book
                        onBookChange()
                        dataManager.loadHadiths(book: book)
                        selectedIndex = 0
                    }
                }) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(book.displayName)
                                .font(.nohemiCaption)
                                .foregroundColor(.black)
                            Text(book.arabicName)
                                .font(.caption2)
                                .foregroundStyle(.gray)
                        }
                    } icon: {
                        Image(systemName: dataManager.currentBook == book ? "checkmark.circle.fill" : book.icon)
                            .foregroundStyle(dataManager.currentBook == book ? .green : .gray)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: dataManager.currentBook.icon)
                    .foregroundStyle(Color.nawawi_darkGreen)
                VStack(alignment: .leading, spacing: 0) {
                    Text(dataManager.currentBook.displayName)
                        .font(.nohemiCaption)
                        .foregroundColor(.black)
                    Text("\(dataManager.hadiths.count) hadiths")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .menuStyle(.borderlessButton)
    }
}