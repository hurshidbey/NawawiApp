//
//  Hadith.swift
//  Nawawi
//
//  Created by Khurshid Marazikov on 8/31/25.
//

import Foundation
import SwiftData

@Model
final class Hadith {
    var number: Int
    var arabicText: String
    var englishTranslation: String
    var narrator: String
    var isFavorite: Bool
    var lastViewedDate: Date?
    
    init(number: Int, arabicText: String, englishTranslation: String, narrator: String, isFavorite: Bool = false, lastViewedDate: Date? = nil) {
        self.number = number
        self.arabicText = arabicText
        self.englishTranslation = englishTranslation
        self.narrator = narrator
        self.isFavorite = isFavorite
        self.lastViewedDate = lastViewedDate
    }
}

struct HadithData: Codable {
    let number: Int
    let arabicText: String
    let englishTranslation: String
    let narrator: String
}