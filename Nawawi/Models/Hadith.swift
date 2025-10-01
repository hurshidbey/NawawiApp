//
//  Hadith.swift
//  Nawawi
//
//  Core hadith model representing a single hadith with translations
//  Extracted from MenuBarView for proper model organization
//

import Foundation

struct Hadith: Codable, Identifiable {
    let number: Int
    let arabicText: String
    let englishTranslation: String
    let uzbekTranslation: String?
    let narrator: String

    var id: Int { number }
}
