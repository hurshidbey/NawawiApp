//
//  HadithBook.swift
//  Nawawi
//
//  Represents available hadith collections in the app
//  Now includes all 17 major hadith books (50,884 hadiths total)
//

import Foundation

enum HadithBook: String, CaseIterable, Identifiable {
    // The Forty Collections (Priority 1 - Essential)
    case nawawi40 = "nawawi40"
    case qudsi40 = "qudsi40"

    // The Two Sahihs (Priority 1 - Most Authentic)
    case bukhari = "bukhari"
    case muslim = "muslim"

    // Popular Study Collection (Priority 1)
    case riyad = "riyad"

    // The Four Sunan (Priority 2)
    case abudawud = "abudawud"
    case tirmidhi = "tirmidhi"
    case nasai = "nasai"
    case ibnmajah = "ibnmajah"

    // The Muwatta and Musnad (Priority 2)
    case malik = "malik"
    case ahmed = "ahmed"
    case darimi = "darimi"

    // Specialized Collections (Priority 2)
    case adab = "adab"
    case bulugh = "bulugh"

    // Additional Collections (Priority 3)
    case shahwaliullah40 = "shahwaliullah40"
    case shamail = "shamail"
    case mishkat = "mishkat"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nawawi40: return "40 Hadith Nawawi"
        case .qudsi40: return "40 Hadith Qudsi"
        case .bukhari: return "Sahih al-Bukhari"
        case .muslim: return "Sahih Muslim"
        case .riyad: return "Riyad as-Salihin"
        case .abudawud: return "Sunan Abi Dawud"
        case .tirmidhi: return "Jami' al-Tirmidhi"
        case .nasai: return "Sunan al-Nasa'i"
        case .ibnmajah: return "Sunan Ibn Majah"
        case .malik: return "Muwatta Malik"
        case .ahmed: return "Musnad Ahmad"
        case .darimi: return "Sunan al-Darimi"
        case .adab: return "Al-Adab Al-Mufrad"
        case .bulugh: return "Bulugh al-Maram"
        case .shahwaliullah40: return "40 Hadith Shah Waliullah"
        case .shamail: return "Shama'il Muhammadiyah"
        case .mishkat: return "Mishkat al-Masabih"
        }
    }

    var arabicName: String {
        switch self {
        case .nawawi40: return "الأربعون النووية"
        case .qudsi40: return "الأربعون القدسية"
        case .bukhari: return "صحيح البخاري"
        case .muslim: return "صحيح مسلم"
        case .riyad: return "رياض الصالحين"
        case .abudawud: return "سنن أبي داود"
        case .tirmidhi: return "جامع الترمذي"
        case .nasai: return "سنن النسائي"
        case .ibnmajah: return "سنن ابن ماجه"
        case .malik: return "موطأ مالك"
        case .ahmed: return "مسند أحمد"
        case .darimi: return "سنن الدارمي"
        case .adab: return "الأدب المفرد"
        case .bulugh: return "بلوغ المرام"
        case .shahwaliullah40: return "أربعون ولي الله"
        case .shamail: return "الشمائل المحمدية"
        case .mishkat: return "مشكاة المصابيح"
        }
    }

    var shortName: String {
        switch self {
        case .nawawi40: return "Nawawi"
        case .qudsi40: return "Qudsi"
        case .bukhari: return "Bukhari"
        case .muslim: return "Muslim"
        case .riyad: return "Riyad"
        case .abudawud: return "Abu Dawud"
        case .tirmidhi: return "Tirmidhi"
        case .nasai: return "Nasa'i"
        case .ibnmajah: return "Ibn Majah"
        case .malik: return "Malik"
        case .ahmed: return "Ahmad"
        case .darimi: return "Darimi"
        case .adab: return "Adab"
        case .bulugh: return "Bulugh"
        case .shahwaliullah40: return "Shah Wali"
        case .shamail: return "Shamail"
        case .mishkat: return "Mishkat"
        }
    }

    var description: String {
        switch self {
        case .nawawi40: return "Essential teachings compiled by Imam Nawawi"
        case .qudsi40: return "Sacred hadiths - words of Allah through the Prophet"
        case .bukhari: return "Most authentic hadith collection"
        case .muslim: return "Second most authentic hadith collection"
        case .riyad: return "Gardens of the Righteous - popular study collection"
        case .abudawud: return "Comprehensive collection of prophetic traditions"
        case .tirmidhi: return "Hadith collection with authenticity grades"
        case .nasai: return "Collection focused on jurisprudence"
        case .ibnmajah: return "One of the six canonical hadith collections"
        case .malik: return "Earliest hadith collection by Imam Malik"
        case .ahmed: return "Extensive collection by Imam Ahmad ibn Hanbal"
        case .darimi: return "Early hadith collection organized by topic"
        case .adab: return "Prophetic teachings on manners and ethics"
        case .bulugh: return "Hadiths related to Islamic jurisprudence"
        case .shahwaliullah40: return "40 selected hadiths by Shah Waliullah"
        case .shamail: return "Descriptions of the Prophet's character and appearance"
        case .mishkat: return "Comprehensive collection of authentic hadiths"
        }
    }

    var fileName: String {
        switch self {
        case .nawawi40: return "nawawi40.json"
        case .qudsi40: return "qudsi40.json"
        case .bukhari: return "bukhari.json"
        case .muslim: return "muslim.json"
        case .riyad: return "riyad.json"
        case .abudawud: return "abudawud.json"
        case .tirmidhi: return "tirmidhi.json"
        case .nasai: return "nasai.json"
        case .ibnmajah: return "ibnmajah.json"
        case .malik: return "malik.json"
        case .ahmed: return "ahmed.json"
        case .darimi: return "darimi.json"
        case .adab: return "adab.json"
        case .bulugh: return "bulugh.json"
        case .shahwaliullah40: return "shahwaliullah40.json"
        case .shamail: return "shamail.json"
        case .mishkat: return "mishkat.json"
        }
    }

    var icon: String {
        switch self {
        case .nawawi40: return "book.fill"
        case .qudsi40: return "star.fill"
        case .bukhari: return "book.closed.fill"
        case .muslim: return "book.closed.fill"
        case .riyad: return "leaf.fill"
        case .abudawud: return "text.book.closed"
        case .tirmidhi: return "text.book.closed"
        case .nasai: return "text.book.closed"
        case .ibnmajah: return "text.book.closed"
        case .malik: return "books.vertical.fill"
        case .ahmed: return "books.vertical.fill"
        case .darimi: return "books.vertical.fill"
        case .adab: return "heart.text.square.fill"
        case .bulugh: return "flag.fill"
        case .shahwaliullah40: return "sparkles"
        case .shamail: return "person.fill"
        case .mishkat: return "lamp.desk.fill"
        }
    }

    var category: BookCategory {
        switch self {
        case .nawawi40, .qudsi40, .shahwaliullah40:
            return .forties
        case .bukhari, .muslim:
            return .sahihayn
        case .abudawud, .tirmidhi, .nasai, .ibnmajah:
            return .sunan
        case .malik, .ahmed, .darimi:
            return .musnad
        case .riyad, .adab, .bulugh, .shamail, .mishkat:
            return .specialized
        }
    }

    /// Offset to match sunnah.com numbering
    /// Some books use different editions with different hadith numbering
    var sunnahComOffset: Int {
        switch self {
        case .ibnmajah:
            return 264  // Our DB numbering is 264 hadiths behind sunnah.com
        default:
            return 0
        }
    }

    /// Get the sunnah.com reference number for a hadith
    func sunnahComReference(for hadithNumber: Int) -> Int {
        return hadithNumber + sunnahComOffset
    }
}

enum BookCategory: String, CaseIterable {
    case forties = "The Forty Collections"
    case sahihayn = "The Two Sahihs"
    case sunan = "The Four Sunan"
    case musnad = "Musnad Collections"
    case specialized = "Specialized Collections"

    var arabicName: String {
        switch self {
        case .forties: return "الأربعينيات"
        case .sahihayn: return "الصحيحان"
        case .sunan: return "السنن الأربعة"
        case .musnad: return "المسانيد"
        case .specialized: return "المجموعات المتخصصة"
        }
    }
}
