//
//  Language.swift
//  Vika
//

import Foundation

struct Language: Identifiable, Hashable {
    let id: String
    /// BCP-47 language code (bundle / Locale)
    let code: String
    let name: String
    let flag: String

    static let english = Language(id: "en", code: "en", name: "English", flag: "🇺🇸")
    static let french = Language(id: "fr", code: "fr", name: "French", flag: "🇫🇷")
    static let german = Language(id: "de", code: "de", name: "German", flag: "🇩🇪")
    static let spanish = Language(id: "es", code: "es", name: "Spanish", flag: "🇪🇸")
    static let swedish = Language(id: "sv", code: "sv", name: "Swedish", flag: "🇸🇪")

    static let allLanguages: [Language] = [.english, .french, .german, .spanish, .swedish]

    static func language(forCode code: String) -> Language {
        allLanguages.first { $0.code == code } ?? .english
    }
}
