//
//  HadithActionService.swift
//  Nawawi
//
//  Centralized service for hadith export, share, and clipboard operations
//  Eliminates duplicate code across MenuBarView and MainWindowView
//

import Foundation
import AppKit
import SwiftUI
import Combine

@MainActor
class HadithActionService: ObservableObject {
    @Published var copiedToClipboard = false

    // MARK: - Export Operations

    /// Export hadith to clipboard in specified format
    func exportToClipboard(_ hadith: Hadith, format: ExportFormat, dataManager: HadithDataManager) {
        let text = dataManager.exportHadith(hadith, format: format)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        // Show feedback
        withAnimation {
            copiedToClipboard = true
        }

        // Reset after delay
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            withAnimation {
                copiedToClipboard = false
            }
        }
    }

    /// Copy text directly to clipboard (simple version)
    func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    // MARK: - Share Operations

    /// Show native macOS share sheet for hadith
    func shareHadith(_ hadith: Hadith, dataManager: HadithDataManager, from view: NSView? = nil) {
        let text = dataManager.exportHadith(hadith, format: .plain)
        let sharingPicker = NSSharingServicePicker(items: [text])

        // Use provided view or fallback to key window
        let sourceView = view ?? NSApp.keyWindow?.contentView ?? NSView()
        sharingPicker.show(relativeTo: .zero, of: sourceView, preferredEdge: .minY)
    }

    /// Share text directly (simple version)
    func shareText(_ text: String, from view: NSView? = nil) {
        let sharingPicker = NSSharingServicePicker(items: [text])
        let sourceView = view ?? NSApp.keyWindow?.contentView ?? NSView()
        sharingPicker.show(relativeTo: .zero, of: sourceView, preferredEdge: .minY)
    }

    // MARK: - Export Helper

    /// Get formatted hadith text without clipboard operation
    func getFormattedText(_ hadith: Hadith, format: ExportFormat, dataManager: HadithDataManager) -> String {
        return dataManager.exportHadith(hadith, format: format)
    }
}
