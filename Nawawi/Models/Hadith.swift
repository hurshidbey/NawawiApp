//
//  Hadith.swift
//  Nawawi
//
//  Core hadith model representing a single hadith with translations
//  Enhanced with book and chapter context for rich Islamic knowledge platform
//

import Foundation

// MARK: - Main Hadith Model

struct Hadith: Codable, Identifiable {
    // Core identification
    let number: Int                 // Display number for UI (1-40)
    let globalId: Int?              // Unique ID across all collections
    let idInBook: Int?              // Position within specific book

    // Content
    let arabicText: String
    let englishTranslation: String
    let uzbekTranslation: String?
    let narrator: String

    // Context (NEW - for rich features)
    let bookId: Int?
    let chapterId: Int?
    let book: BookInfo?
    let chapter: ChapterInfo?

    var id: Int { number }

    // Coding keys for backward compatibility
    enum CodingKeys: String, CodingKey {
        case number
        case globalId  // Now matches JSON field name directly
        case idInBook
        case arabicText
        case englishTranslation
        case uzbekTranslation
        case narrator
        case bookId
        case chapterId
        case book
        case chapter
    }

    // Custom decoder to handle both "id" and "globalId" field names
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        number = try container.decode(Int.self, forKey: .number)

        // Try "globalId" first (newer format), fall back to "id" (older format)
        if let gid = try? container.decodeIfPresent(Int.self, forKey: .globalId) {
            globalId = gid
        } else {
            // Try alternative "id" key for backwards compatibility
            let altContainer = try decoder.container(keyedBy: AlternativeCodingKeys.self)
            globalId = try? altContainer.decodeIfPresent(Int.self, forKey: .id)
        }

        idInBook = try container.decodeIfPresent(Int.self, forKey: .idInBook)
        arabicText = try container.decode(String.self, forKey: .arabicText)
        englishTranslation = try container.decode(String.self, forKey: .englishTranslation)
        uzbekTranslation = try container.decodeIfPresent(String.self, forKey: .uzbekTranslation)
        narrator = try container.decode(String.self, forKey: .narrator)
        bookId = try container.decodeIfPresent(Int.self, forKey: .bookId)
        chapterId = try container.decodeIfPresent(Int.self, forKey: .chapterId)
        book = try container.decodeIfPresent(BookInfo.self, forKey: .book)
        chapter = try container.decodeIfPresent(ChapterInfo.self, forKey: .chapter)
    }

    // Custom encoder to always use "globalId" when encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(number, forKey: .number)
        try container.encodeIfPresent(globalId, forKey: .globalId)
        try container.encodeIfPresent(idInBook, forKey: .idInBook)
        try container.encode(arabicText, forKey: .arabicText)
        try container.encode(englishTranslation, forKey: .englishTranslation)
        try container.encodeIfPresent(uzbekTranslation, forKey: .uzbekTranslation)
        try container.encode(narrator, forKey: .narrator)
        try container.encodeIfPresent(bookId, forKey: .bookId)
        try container.encodeIfPresent(chapterId, forKey: .chapterId)
        try container.encodeIfPresent(book, forKey: .book)
        try container.encodeIfPresent(chapter, forKey: .chapter)
    }

    // Alternative coding keys for backwards compatibility
    private enum AlternativeCodingKeys: String, CodingKey {
        case id
    }
}

// MARK: - Book Information

struct BookInfo: Codable, Identifiable {
    let id: Int
    let title: String
    let arabicTitle: String
    let author: String
    let arabicAuthor: String
    let introduction: String?
    let totalHadiths: Int
}

// MARK: - Chapter Information

struct ChapterInfo: Codable, Identifiable {
    let id: Int
    let title: String
    let arabicTitle: String
    let bookId: Int
}
