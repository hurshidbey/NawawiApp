//
//  HadithDetailView.swift
//  Nawawi
//
//  Created by Khurshid Marazikov on 8/31/25.
//

import SwiftUI

struct HadithDetailView: View {
    let hadith: Hadith
    @EnvironmentObject var hadithManager: HadithManager
    @Environment(\.dismiss) private var dismiss
    @State private var copiedToClipboard = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Hadith #\(hadith.number)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Narrator: \(hadith.narrator)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            hadithManager.toggleFavorite(for: hadith)
                        }) {
                            Image(systemName: hadith.isFavorite ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(hadith.isFavorite ? .red : .gray)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: shareHadith) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: copyToClipboard) {
                            Image(systemName: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.doc")
                                .font(.title2)
                                .foregroundColor(copiedToClipboard ? .green : .primary)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Divider()
                
                VStack(alignment: .trailing, spacing: 16) {
                    Text("Arabic Text")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(hadith.arabicText)
                        .font(.custom("SF Arabic", size: 28))
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.05))
                        )
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("English Translation")
                        .font(.headline)
                    
                    Text(hadith.englishTranslation)
                        .font(.system(size: 18))
                        .lineSpacing(8)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.05))
                        )
                }
                
                if let lastViewed = hadith.lastViewedDate {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("Last viewed: \(lastViewed.formatted())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(30)
        }
        .frame(width: 700, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func shareHadith() {
        let text = """
        Hadith #\(hadith.number)
        
        Arabic:
        \(hadith.arabicText)
        
        English Translation:
        \(hadith.englishTranslation)
        
        Narrator: \(hadith.narrator)
        
        From Imam Nawawi's 40 Hadith Collection
        """
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        if let sharingService = NSSharingService(named: .composeMessage) {
            sharingService.perform(withItems: [text])
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