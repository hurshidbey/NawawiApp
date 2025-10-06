//
//  HadithDataManager.swift
//  Nawawi
//
//  Data management layer for hadiths with caching and error handling
//

import Foundation
import SwiftUI
import Combine

@MainActor
class HadithDataManager: ObservableObject {
    @Published var hadiths: [Hadith] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastLoadTime: Date?
    @Published var currentBook: HadithBook = .nawawi40

    private let cache = NSCache<NSString, NSData>()

    // MARK: - Performance Caches
    // Hadith number → index lookup for O(1) access
    private var numberToIndexMap: [Int: Int] = [:]

    // Chapter ID → array of hadiths in that chapter
    private var chapterCache: [Int: [Hadith]] = [:]

    init() {
        loadHadiths(book: currentBook)
    }

    func loadHadiths(book: HadithBook = .nawawi40) {
        print("🚀 loadHadiths() called for: \(book.displayName)")
        isLoading = true
        error = nil
        currentBook = book

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                // TEMPORARILY DISABLE CACHE to ensure fresh decode
                // TODO: Re-enable after fixing decoder issue
                /*
                // Check cache first
                let cacheKey = book.fileName as NSString
                if let cachedData = self.cache.object(forKey: cacheKey) as Data? {
                    let decoded = try JSONDecoder().decode([Hadith].self, from: cachedData)
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.hadiths = decoded
                        self.rebuildCaches()
                        self.isLoading = false
                        self.lastLoadTime = Date()
                    }
                    return
                }
                */

                // Load from bundle
                let resourceName = book.fileName.replacingOccurrences(of: ".json", with: "")
                guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
                    throw HadithError.fileNotFound
                }

                let data = try Data(contentsOf: url)
                print("📖 Loading \(book.displayName): File size = \(String(format: "%.2f", Double(data.count) / 1024.0 / 1024.0)) MB")

                let startTime = Date()
                let decoded = try JSONDecoder().decode([Hadith].self, from: data)
                let decodeTime = Date().timeIntervalSince(startTime)
                print("✅ Successfully decoded \(decoded.count) hadiths from \(book.displayName) in \(String(format: "%.2f", decodeTime))s")

                // Cache the data (disabled for now)
                // let cacheKey = book.fileName as NSString
                // self.cache.setObject(data as NSData, forKey: cacheKey)

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.hadiths = decoded
                    self.rebuildCaches()
                    self.isLoading = false
                    self.lastLoadTime = Date()
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.error = error
                    self.isLoading = false
                    print("❌ Error loading hadiths from \(book.displayName): \(error)")
                    print("   Error details: \(error.localizedDescription)")
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("   Missing key: \(key.stringValue) at path: \(context.codingPath)")
                        case .typeMismatch(let type, let context):
                            print("   Type mismatch: expected \(type) at path: \(context.codingPath)")
                        case .valueNotFound(let type, let context):
                            print("   Value not found: \(type) at path: \(context.codingPath)")
                        case .dataCorrupted(let context):
                            print("   Data corrupted at path: \(context.codingPath)")
                        @unknown default:
                            print("   Unknown decoding error")
                        }
                    }
                }
            }
        }
    }

    func searchHadiths(query: String, language: AppLanguage, favoritesOnly: Bool = false, favorites: Set<Int> = []) -> [Hadith] {
        var filtered = hadiths

        if favoritesOnly {
            filtered = filtered.filter { favorites.contains($0.number) }
        }

        if !query.isEmpty {
            filtered = filtered.filter { hadith in
                let searchTarget: String
                switch language {
                case .arabic:
                    searchTarget = hadith.arabicText
                case .english:
                    searchTarget = hadith.englishTranslation
                }

                let searchableContent = """
                \(searchTarget)
                \(hadith.narrator)
                \(hadith.arabicText)
                Hadith \(hadith.number)
                """

                return searchableContent.localizedCaseInsensitiveContains(query)
            }
        }

        return filtered
    }

    func getRandomHadith() -> Hadith? {
        hadiths.randomElement()
    }

    // MARK: - Cache Management

    /// Rebuild all performance caches after hadiths change
    private func rebuildCaches() {
        // Clear existing caches
        numberToIndexMap.removeAll(keepingCapacity: true)
        chapterCache.removeAll(keepingCapacity: true)

        // Build number → index map
        for (index, hadith) in hadiths.enumerated() {
            numberToIndexMap[hadith.number] = index
        }

        // Build chapter cache
        for hadith in hadiths {
            if let chapterId = hadith.chapterId {
                chapterCache[chapterId, default: []].append(hadith)
            }
        }
    }

    // MARK: - High-Performance Lookups

    /// Get index for hadith number in O(1) time
    func indexForHadithNumber(_ number: Int) -> Int? {
        return numberToIndexMap[number]
    }

    /// Get all hadiths in a chapter in O(1) time
    func hadithsInChapter(_ chapterId: Int) -> [Hadith] {
        return chapterCache[chapterId] ?? []
    }

    /// Find hadith number's index in a filtered list
    func indexInFilteredList(_ hadithNumber: Int, filteredHadiths: [Hadith]) -> Int? {
        // For small filtered lists, linear search is fast enough
        return filteredHadiths.firstIndex(where: { $0.number == hadithNumber })
    }

    func exportHadith(_ hadith: Hadith, format: ExportFormat) -> String {
        switch format {
        case .plain:
            return """
            Hadith #\(hadith.number)

            Arabic:
            \(hadith.arabicText)

            English:
            \(hadith.englishTranslation)

            Narrator: \(hadith.narrator)
            """

        case .markdown:
            return """
            # Hadith #\(hadith.number)

            ## Arabic
            > \(hadith.arabicText)

            ## English Translation
            \(hadith.englishTranslation)

            **Narrator:** \(hadith.narrator)
            """

        case .json:
            if let data = try? JSONEncoder().encode(hadith),
               let string = String(data: data, encoding: .utf8) {
                return string
            }
            return ""
        }
    }
}

enum HadithError: LocalizedError {
    case fileNotFound
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Hadith file not found in bundle"
        case .decodingError(let message):
            return "Failed to decode hadiths: \(message)"
        }
    }
}

enum ExportFormat {
    case plain
    case markdown
    case json
}
