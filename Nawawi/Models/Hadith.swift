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
        case globalId = "id"
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

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case arabicTitle = "arabic_title"
        case author
        case arabicAuthor = "arabic_author"
        case introduction
        case totalHadiths = "total_hadiths"
    }
}

// MARK: - Chapter Information

struct ChapterInfo: Codable, Identifiable {
    let id: Int
    let title: String
    let arabicTitle: String
    let bookId: Int

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case arabicTitle = "arabic_title"
        case bookId
    }
}
