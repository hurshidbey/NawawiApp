//
//  MenuBarView.swift
//  Nawawi
//
//  Created by Khurshid Marazikov on 8/31/25.
//

import SwiftUI
import SwiftData

struct MenuBarView: View {
    @EnvironmentObject var hadithManager: HadithManager
    @EnvironmentObject var notificationManager: NotificationManager
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @State private var showSettings = false
    @State private var showHadithDetail = false
    @State private var selectedHadith: Hadith?
    
    var currentSettings: Settings? {
        settings.first
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let hadith = hadithManager.currentHadith {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Hadith #\(hadith.number)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            hadithManager.toggleFavorite(for: hadith)
                        }) {
                            Image(systemName: hadith.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(hadith.isFavorite ? .red : .gray)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Divider()
                    
                    if currentSettings?.showArabicText ?? true {
                        Text(hadith.arabicText)
                            .font(.custom("SF Arabic", size: currentSettings?.fontSize.arabicSize ?? 22))
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .lineLimit(3)
                            .padding(.vertical, 4)
                    }
                    
                    if currentSettings?.showEnglishTranslation ?? true {
                        Text(hadith.englishTranslation)
                            .font(.system(size: currentSettings?.fontSize.englishSize ?? 16))
                            .lineLimit(4)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("— \(hadith.narrator)")
                        .font(.caption)
                        .italic()
                        .foregroundColor(.secondary)
                    
                    Button("Read Full Hadith") {
                        selectedHadith = hadith
                        showHadithDetail = true
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                }
                .padding()
                .frame(width: 400)
            } else {
                Text("Loading hadiths...")
                    .padding()
            }
            
            Divider()
            
            HStack(spacing: 16) {
                Button(action: {
                    hadithManager.selectNextHadith()
                }) {
                    Label("Next Hadith", systemImage: "arrow.forward.circle")
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    showSettings = true
                }) {
                    Label("Settings", systemImage: "gearshape")
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .foregroundColor(.red)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(VisualEffectView())
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(hadithManager)
                .environmentObject(notificationManager)
                .modelContainer(for: [Settings.self, Hadith.self])
        }
        .sheet(isPresented: $showHadithDetail) {
            if let hadith = selectedHadith {
                HadithDetailView(hadith: hadith)
                    .environmentObject(hadithManager)
                    .interactiveDismissDisabled(false)
            }
        }
        .onAppear {
            setupInitialSettings()
            hadithManager.loadHadiths()
        }
    }
    
    private func setupInitialSettings() {
        if settings.isEmpty {
            let newSettings = Settings()
            modelContext.insert(newSettings)
            hadithManager.refreshSettings(newSettings)
        } else if let existingSettings = settings.first {
            hadithManager.refreshSettings(existingSettings)
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .menu
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}