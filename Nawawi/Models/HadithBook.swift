//
//  HadithBook.swift
//  Nawawi
//
//  Represents available hadith collections in the app
//

import Foundation

enum HadithBook: String, CaseIterable, Identifiable {
    case nawawi40 = "nawawi40"
    case qudsi40 = "qudsi40"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nawawi40:
            return "40 Hadith Nawawi"
        case .qudsi40:
            return "40 Hadith Qudsi"
        }
    }

    var arabicName: String {
        switch self {
        case .nawawi40:
            return "الأربعون النووية"
        case .qudsi40:
            return "الأربعون القدسية"
        }
    }

    var description: String {
        switch self {
        case .nawawi40:
            return "Essential teachings compiled by Imam Nawawi"
        case .qudsi40:
            return "Sacred hadiths - words of Allah through the Prophet"
        }
    }

    var fileName: String {
        switch self {
        case .nawawi40:
            return "hadiths.json"
        case .qudsi40:
            return "qudsi40.json"
        }
    }

    var icon: String {
        switch self {
        case .nawawi40:
            return "book.fill"
        case .qudsi40:
            return "star.fill"
        }
    }
}
