//
//  CurrencyRegionDisplay.swift
//  Vika
//

import SwiftUI

/// User override lives in `UserDefaults` / `@AppStorage` under `appStorageKey`. Empty = use device locale currency.
enum LocaleCurrency {
    static let appStorageKey = "selectedCurrencyISOCode"

    static func resolvedCode(storedOverride: String) -> String {
        let trimmed = storedOverride.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed.uppercased() }
        if let code = Locale.current.currency?.identifier, !code.isEmpty {
            return code
        }
        return "USD"
    }

    /// Symbol for a given ISO 4217 code (e.g. SEK → `kr`).
    static func currencySymbol(forCode code: String) -> String {
        let upper = code.uppercased()
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = upper
        formatter.locale = Locale(identifier: "en_US")
        return formatter.currencySymbol ?? upper
    }

    static var iso4217Code: String {
        resolvedCode(storedOverride: UserDefaults.standard.string(forKey: appStorageKey) ?? "")
    }

    static var flagEmoji: String {
        CurrencyRegionFlag.flagEmoji(forCurrencyCode: iso4217Code)
    }

    static let amountCoral = Color(red: 0.88, green: 0.42, blue: 0.38)
}

/// Flag + ISO code (e.g. 🇸🇪 SEK) for read-only and field trailing labels. Updates when the user changes currency in Settings.
struct CurrencyCodeFlagLabel: View {
    @AppStorage(LocaleCurrency.appStorageKey) private var storedCurrencyCode = ""

    var flagFont: Font = .title3
    var codeFont: Font = .subheadline.weight(.semibold)

    private var resolvedCode: String {
        LocaleCurrency.resolvedCode(storedOverride: storedCurrencyCode)
    }

    var body: some View {
        let flag = CurrencyRegionFlag.flagEmoji(forCurrencyCode: resolvedCode)
        HStack(spacing: 8) {
            if !flag.isEmpty {
                Text(flag)
                    .font(flagFont)
            }
            Text(resolvedCode)
                .font(codeFont)
                .foregroundStyle(LocaleCurrency.amountCoral)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

/// Maps ISO 4217 currency codes to regional flag emojis (e.g. SEK → 🇸🇪).
enum CurrencyRegionFlag {
    static func flagEmoji(forCurrencyCode code: String) -> String {
        let upper = code.uppercased()
        if let region = currencyToRegion[upper] {
            return regionFlagEmoji(regionCode: region)
        }
        if let currency = Locale.current.currency,
           currency.identifier.uppercased() == upper,
           let region = Locale.current.region?.identifier,
           region.count == 2 {
            return regionFlagEmoji(regionCode: region)
        }
        return ""
    }

    private static func regionFlagEmoji(regionCode: String) -> String {
        let upper = regionCode.uppercased()
        guard upper.count == 2 else { return "" }
        return upper.unicodeScalars.compactMap { s -> UnicodeScalar? in
            guard (65...90).contains(s.value) else { return nil }
            return UnicodeScalar(0x1F1E6 + (s.value - 65))
        }
        .map { String($0) }
        .joined()
    }

    private static let currencyToRegion: [String: String] = [
        "SEK": "SE", "USD": "US", "EUR": "EU", "GBP": "GB", "NOK": "NO", "DKK": "DK",
        "CHF": "CH", "ISK": "IS", "PLN": "PL", "CZK": "CZ", "HUF": "HU", "RON": "RO",
        "BGN": "BG", "HRK": "HR", "RSD": "RS", "BAM": "BA", "MKD": "MK", "ALL": "AL",
        "UAH": "UA", "BYN": "BY", "RUB": "RU", "TRY": "TR", "ILS": "IL", "JOD": "JO",
        "AED": "AE", "SAR": "SA", "QAR": "QA", "KWD": "KW", "BHD": "BH", "OMR": "OM",
        "INR": "IN", "PKR": "PK", "BDT": "BD", "LKR": "LK", "NPR": "NP", "CNY": "CN",
        "JPY": "JP", "KRW": "KR", "TWD": "TW", "HKD": "HK", "MOP": "MO", "SGD": "SG",
        "MYR": "MY", "THB": "TH", "IDR": "ID", "PHP": "PH", "VND": "VN", "AUD": "AU",
        "NZD": "NZ", "FJD": "FJ", "CAD": "CA", "MXN": "MX", "BRL": "BR", "ARS": "AR",
        "CLP": "CL", "COP": "CO", "PEN": "PE", "UYU": "UY", "ZAR": "ZA", "EGP": "EG",
        "NGN": "NG", "KES": "KE", "GHS": "GH", "MAD": "MA", "TND": "TN", "DZD": "DZ"
    ]
}
