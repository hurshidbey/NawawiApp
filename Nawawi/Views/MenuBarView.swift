//
//  MenuBarView.swift
//  Nawawi
//
//  Created by Khurshid Marazikov on 8/31/25.
//

import SwiftUI
import UserNotifications

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @State private var hadiths: [Hadith] = []
    @State private var showFullHadith = false
    @State private var showSettings = false
    @State private var showingFavoritesOnly = false
    @State private var searchText = ""
    @State private var currentView: ViewMode = .main
    
    @FocusState private var isSearchFocused: Bool
    
    enum ViewMode {
        case main
        case settings
        case detail
    }
    
    var currentHadith: Hadith? {
        guard !hadiths.isEmpty else { return nil }
        let displayHadiths = filteredHadiths
        guard !displayHadiths.isEmpty else { 
            // Reset index when no filtered results
            DispatchQueue.main.async {
                appState.currentHadithIndex = 0
            }
            return nil
        }
        // Ensure index is within bounds
        let safeIndex = min(max(0, appState.currentHadithIndex), displayHadiths.count - 1)
        if safeIndex != appState.currentHadithIndex {
            DispatchQueue.main.async {
                appState.currentHadithIndex = safeIndex
            }
        }
        return displayHadiths[safeIndex]
    }
    
    var filteredHadiths: [Hadith] {
        var filtered = hadiths
        
        if showingFavoritesOnly {
            filtered = filtered.filter { appState.favorites.contains($0.number) }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { hadith in
                // Search in the appropriate language
                let searchTarget: String
                switch appState.selectedLanguage {
                case .arabic:
                    searchTarget = hadith.arabicText
                case .uzbek:
                    searchTarget = hadith.uzbekTranslation ?? hadith.englishTranslation
                case .english:
                    searchTarget = hadith.englishTranslation
                }
                
                return searchTarget.localizedCaseInsensitiveContains(searchText) ||
                       hadith.narrator.localizedCaseInsensitiveContains(searchText) ||
                       hadith.arabicText.contains(searchText) ||
                       String(hadith.number).contains(searchText)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        ZStack {
            // Glassy background like Weather app
            VisualEffectBackground()
            
            switch currentView {
            case .settings:
                // Settings view inline
                SettingsInlineView(currentView: $currentView)
                    .environmentObject(appState)
            case .detail:
                // Detail view inline
                if let hadith = currentHadith {
                    HadithDetailInlineView(hadith: hadith, currentView: $currentView)
                        .environmentObject(appState)
                }
            case .main:
                VStack(spacing: 0) {
                    // Header with search
                    HeaderView(searchText: $searchText, isSearchFocused: $isSearchFocused)
                        .environmentObject(appState)
                    
                    Divider()
                        .opacity(0.5)
                    
                    // Main content
                    if let hadith = currentHadith {
                        ScrollView {
                            VStack(spacing: 20) {
                                // Hadith card with glass effect
                                HadithCard(hadith: hadith)
                                    .environmentObject(appState)
                                    .onTapGesture {
                                        currentView = .detail
                                    }
                            }
                            .padding()
                        }
                        .frame(width: 380, height: 420)
                    } else {
                        ContentUnavailableView(
                            "No Hadiths",
                            systemImage: "book.closed",
                            description: Text("No hadiths match your search")
                        )
                        .frame(width: 380, height: 420)
                    }
                    
                    Divider()
                        .opacity(0.5)
                    
                    // Bottom toolbar
                    ToolbarView(
                        showingFavoritesOnly: $showingFavoritesOnly,
                        showSettings: $showSettings,
                        filteredCount: filteredHadiths.count,
                        currentView: $currentView,
                        navigateNext: navigateToNextHadith,
                        navigatePrevious: navigateToPreviousHadith
                    )
                    .environmentObject(appState)
                }
            }
        }
        .onAppear {
            loadHadiths()
        }
        .onReceive(appState.$showSettings) { show in
            showSettings = show
        }
    }
    
    private func loadHadiths() {
        guard let url = Bundle.main.url(forResource: "hadiths", withExtension: "json") else {
            print("Error: Could not find hadiths.json in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Hadith].self, from: data)
            hadiths = decoded
            print("Successfully loaded \(decoded.count) hadiths")
        } catch {
            print("Error loading hadiths: \(error)")
            // Try to provide more detailed error information
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription)")
                case .keyNotFound(let key, let context):
                    print("Key '\(key.stringValue)' not found: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch for type \(type): \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("Value not found for type \(type): \(context.debugDescription)")
                @unknown default:
                    print("Unknown decoding error")
                }
            }
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
}

// MARK: - Header View
struct HeaderView: View {
    @Binding var searchText: String
    @FocusState.Binding var isSearchFocused: Bool
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "book.fill")
                .font(.title2)
                .foregroundStyle(.tint)
                .symbolEffect(.pulse, isActive: appState.hasActiveReminder)
            
            Text("40 Hadith")
                .font(.headline)
            
            // Language selector
            Menu {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Button(action: { appState.selectedLanguage = language }) {
                        HStack {
                            Text(language.flag)
                            Text(language.displayName)
                            if appState.selectedLanguage == language {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Text(appState.selectedLanguage.flag)
                    .font(.title3)
            }
            .menuStyle(.borderlessButton)
            
            Spacer()
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .onChange(of: searchText) { _, _ in
                        // Reset to first result when search changes
                        appState.currentHadithIndex = 0
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.regularMaterial, in: Capsule())
            .frame(width: 150)
        }
        .padding()
    }
}

// MARK: - Hadith Card
struct HadithCard: View {
    let hadith: Hadith
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("\(hadith.number)", systemImage: "number.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        appState.toggleFavorite(hadith.number)
                    }
                }) {
                    Image(systemName: appState.favorites.contains(hadith.number) ? "heart.fill" : "heart")
                        .foregroundStyle(appState.favorites.contains(hadith.number) ? .red : .secondary)
                        .symbolEffect(.bounce, value: appState.favorites.contains(hadith.number))
                }
                .buttonStyle(.plain)
            }
            
            // Arabic text with glass background (always shown)
            if appState.selectedLanguage == .arabic || appState.selectedLanguage == .english {
                Text(hadith.arabicText)
                    .font(.system(size: 20))
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineLimit(3)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .environment(\.layoutDirection, .rightToLeft)
            }
            
            // Translation based on selected language
            Group {
                switch appState.selectedLanguage {
                case .arabic:
                    // Arabic only - no additional translation needed
                    EmptyView()
                case .english:
                    Text(hadith.englishTranslation)
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                        .lineLimit(4)
                        .lineSpacing(4)
                case .uzbek:
                    if let uzbekTranslation = hadith.uzbekTranslation {
                        Text(uzbekTranslation)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                            .lineLimit(4)
                            .lineSpacing(4)
                    } else {
                        // Fallback to English if Uzbek not available
                        Text(hadith.englishTranslation)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                            .lineLimit(4)
                            .lineSpacing(4)
                            .opacity(0.7)
                        Text("(Translation not yet available)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Narrator
            Label(hadith.narrator, systemImage: "person.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
    }
}

// MARK: - Toolbar View
struct ToolbarView: View {
    @Binding var showingFavoritesOnly: Bool
    @Binding var showSettings: Bool
    let filteredCount: Int
    @Binding var currentView: MenuBarView.ViewMode
    @EnvironmentObject var appState: AppState
    let navigateNext: () -> Void
    let navigatePrevious: () -> Void
    
    var body: some View {
        HStack {
            // Navigation buttons
            HStack(spacing: 8) {
                Button(action: navigatePrevious) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                .disabled(filteredCount == 0)
                
                Text("\(filteredCount > 0 ? appState.currentHadithIndex + 1 : 0) / \(filteredCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                
                Button(action: navigateNext) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
                .disabled(filteredCount == 0)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation {
                        showingFavoritesOnly.toggle()
                        // Reset index when toggling filter
                        appState.currentHadithIndex = 0
                    }
                }) {
                    Image(systemName: showingFavoritesOnly ? "heart.fill" : "heart")
                        .foregroundStyle(showingFavoritesOnly ? .red : .secondary)
                }
                .buttonStyle(.plain)
                .help("Show Favorites")
                
                Button(action: { currentView = .settings }) {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .help("Settings")
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Quit")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Visual Effect Background
struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Hadith Detail Inline View
struct HadithDetailInlineView: View {
    let hadith: Hadith
    @Binding var currentView: MenuBarView.ViewMode
    @EnvironmentObject var appState: AppState
    @State private var copiedToClipboard = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hadith #\(hadith.number)")
                        .font(.title2.bold())
                    
                    Label(hadith.narrator, systemImage: "person.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        appState.toggleFavorite(hadith.number)
                    }) {
                        Image(systemName: appState.favorites.contains(hadith.number) ? "heart.fill" : "heart")
                            .foregroundStyle(appState.favorites.contains(hadith.number) ? .red : .secondary)
                            .symbolEffect(.bounce, value: appState.favorites.contains(hadith.number))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: copyToClipboard) {
                        Image(systemName: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.doc")
                            .foregroundStyle(copiedToClipboard ? .green : .secondary)
                            .symbolEffect(.bounce, value: copiedToClipboard)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { currentView = .main }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            
            Divider()
                .opacity(0.5)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Language selector
                    HStack {
                        Text("Language:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Picker("", selection: $appState.selectedLanguage) {
                            ForEach(AppLanguage.allCases, id: \.self) { language in
                                HStack {
                                    Text(language.flag)
                                    Text(language.displayName)
                                }
                                .tag(language)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    .padding(.horizontal)
                    
                    // Arabic text (shown for Arabic and English modes)
                    if appState.selectedLanguage == .arabic || appState.selectedLanguage == .english {
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("Arabic")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(hadith.arabicText)
                                .font(.system(size: 18))
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .lineSpacing(6)
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                                .environment(\.layoutDirection, .rightToLeft)
                        }
                    }
                    
                    // Translation based on selected language
                    if appState.selectedLanguage != .arabic {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(appState.selectedLanguage == .uzbek ? "O'zbek tarjimasi" : "Translation")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if appState.selectedLanguage == .uzbek {
                                if let uzbekTranslation = hadith.uzbekTranslation {
                                    Text(uzbekTranslation)
                                        .font(.system(size: 14))
                                        .lineSpacing(4)
                                        .padding(12)
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(hadith.englishTranslation)
                                            .font(.system(size: 14))
                                            .lineSpacing(4)
                                            .opacity(0.7)
                                        
                                        Text("(O'zbek tarjimasi hali mavjud emas)")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                    .padding(12)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                                }
                            } else {
                                Text(hadith.englishTranslation)
                                    .font(.system(size: 14))
                                    .lineSpacing(4)
                                    .padding(12)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
                .padding()
            }
            .frame(width: 380, height: 420)
        }
    }
    
    private func copyToClipboard() {
        let text = """
        Hadith #\(hadith.number)
        
        \(hadith.arabicText)
        
        \(hadith.englishTranslation)
        
        — \(hadith.narrator)
        """
        
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
}

// MARK: - Settings Inline View
struct SettingsInlineView: View {
    @EnvironmentObject var appState: AppState
    @Binding var currentView: MenuBarView.ViewMode
    @State private var selectedTime = Date()
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2.bold())
                
                Spacer()
                
                Button(action: { currentView = .main }) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
                .opacity(0.5)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Reminders section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Notifications", systemImage: "bell")
                            .font(.headline)
                        
                        // Show permission status
                        if permissionStatus == .denied {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
                                Text("Notifications are disabled")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Button("Open System Settings") {
                                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .buttonStyle(.link)
                            .foregroundStyle(.blue)
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
                                    if permissionStatus == .authorized {
                                        appState.scheduleReminder()
                                    } else if permissionStatus == .notDetermined {
                                        appState.requestNotificationPermission { granted in
                                            checkPermissionStatus()
                                            if granted {
                                                appState.scheduleReminder()
                                            } else {
                                                appState.reminderEnabled = false
                                            }
                                        }
                                    } else {
                                        appState.reminderEnabled = false
                                    }
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
                            
                            Button("Test Notification (5 seconds)") {
                                appState.sendTestNotification()
                            }
                            .buttonStyle(.link)
                            .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    // Favorites section
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
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    // Info section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Navigation", systemImage: "arrow.left.arrow.right")
                            .font(.headline)
                        
                        Text("Use the navigation buttons to browse hadiths")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .frame(width: 380, height: 420)
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

struct ShortcutRow: View {
    let keys: String
    let action: String
    
    var body: some View {
        HStack {
            Text(keys)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
            
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