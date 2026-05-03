//
//  SelectCurrencyView.swift
//  Vika
//

import SwiftUI

struct SelectCurrencyView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(LocaleCurrency.appStorageKey) private var selectedCurrencyISOCode = ""
    @AppStorage("selectedLanguage") private var selectedLanguageCode = "en"
    @State private var searchText = ""

    private func t(_ key: VikaL10n.Key) -> String {
        VikaL10n.t(key, languageCode: selectedLanguageCode)
    }

    private var filteredCurrencies: [CurrencyPickerOption] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return CurrencyPickerOption.all }
        return CurrencyPickerOption.all.filter { opt in
            opt.code.lowercased().contains(q) || opt.nameEnglish.lowercased().contains(q)
        }
    }

    private var currentResolvedCode: String {
        LocaleCurrency.resolvedCode(storedOverride: selectedCurrencyISOCode)
    }

    var body: some View {
        NavigationStack {
            List(filteredCurrencies) { option in
                Button {
                    selectedCurrencyISOCode = option.code
                    dismiss()
                } label: {
                    HStack(alignment: .center, spacing: 10) {
                        Text(CurrencyRegionFlag.flagEmoji(forCurrencyCode: option.code))
                            .font(.title2)
                        Text("\(option.code) - \(option.nameEnglish)")
                            .font(.body)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if option.code == currentResolvedCode {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.red)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: Text(t(.selectCurrencySearchPlaceholder)))
            .navigationTitle(t(.selectCurrencyTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(t(.selectCurrencyCancel)) {
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }
}

private struct CurrencyPickerOption: Identifiable {
    let code: String
    let nameEnglish: String
    var id: String { code }

    static let all: [CurrencyPickerOption] = [
        .init(code: "USD", nameEnglish: "US Dollar"),
        .init(code: "EUR", nameEnglish: "Euro"),
        .init(code: "GBP", nameEnglish: "British Pound"),
        .init(code: "JPY", nameEnglish: "Japanese Yen"),
        .init(code: "CAD", nameEnglish: "Canadian Dollar"),
        .init(code: "AUD", nameEnglish: "Australian Dollar"),
        .init(code: "CHF", nameEnglish: "Swiss Franc"),
        .init(code: "CNY", nameEnglish: "Chinese Yuan"),
        .init(code: "SEK", nameEnglish: "Swedish Krona"),
        .init(code: "NZD", nameEnglish: "New Zealand Dollar"),
        .init(code: "MXN", nameEnglish: "Mexican Peso"),
        .init(code: "SGD", nameEnglish: "Singapore Dollar"),
        .init(code: "NOK", nameEnglish: "Norwegian Krone"),
        .init(code: "DKK", nameEnglish: "Danish Krone"),
        .init(code: "PLN", nameEnglish: "Polish Zloty"),
        .init(code: "INR", nameEnglish: "Indian Rupee"),
        .init(code: "KRW", nameEnglish: "South Korean Won"),
        .init(code: "BRL", nameEnglish: "Brazilian Real"),
        .init(code: "ZAR", nameEnglish: "South African Rand")
    ]
}
