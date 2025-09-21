//
//  HadithDataManager.swift
//  Nawawi
//
//  Data management layer for hadiths with caching and error handling
//

import Foundation
import SwiftUI
import Combine

class HadithDataManager: ObservableObject {
    static let shared = HadithDataManager()

    @Published var hadiths: [Hadith] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastLoadTime: Date?

    private let cache = NSCache<NSString, NSData>()
    private let hadithFileName = "hadiths.json"

    init() {
        loadHadiths()
    }

    func loadHadiths() {
        isLoading = true
        error = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                // Check cache first
                if let cachedData = self.cache.object(forKey: self.hadithFileName as NSString) as Data? {
                    let decoded = try JSONDecoder().decode([Hadith].self, from: cachedData)
                    DispatchQueue.main.async {
                        self.hadiths = decoded
                        self.isLoading = false
                        self.lastLoadTime = Date()
                    }
                    return
                }

                // Load from bundle
                guard let url = Bundle.main.url(forResource: "hadiths", withExtension: "json") else {
                    throw HadithError.fileNotFound
                }

                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode([Hadith].self, from: data)

                // Cache the data
                self.cache.setObject(data as NSData, forKey: self.hadithFileName as NSString)

                DispatchQueue.main.async {
                    self.hadiths = decoded
                    self.isLoading = false
                    self.lastLoadTime = Date()
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                    print("Error loading hadiths: \(error)")
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
                case .uzbek:
                    searchTarget = hadith.uzbekTranslation ?? hadith.englishTranslation
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

    func exportHadith(_ hadith: Hadith, format: ExportFormat) -> String {
        switch format {
        case .plain:
            return """
            Hadith #\(hadith.number)

            Arabic:
            \(hadith.arabicText)

            English:
            \(hadith.englishTranslation)

            \(hadith.uzbekTranslation.map { "Uzbek:\n\($0)\n\n" } ?? "")
            Narrator: \(hadith.narrator)
            """

        case .markdown:
            return """
            # Hadith #\(hadith.number)

            ## Arabic
            > \(hadith.arabicText)

            ## English Translation
            \(hadith.englishTranslation)

            \(hadith.uzbekTranslation.map { "## Uzbek Translation\n\($0)\n\n" } ?? "")
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
