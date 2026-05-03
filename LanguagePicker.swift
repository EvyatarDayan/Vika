//
//  LanguagePicker.swift
//  Vika
//

import SwiftUI

struct LanguagePickerButton: View {
    enum Style {
        /// Full chip (onboarding, large tap target)
        case regular
        /// Narrow chip for navigation bars
        case toolbar
    }

    var style: Style = .regular

    @AppStorage("selectedLanguage") private var selectedLanguageCode = "en"
    @State private var showingModal = false

    private var language: Language {
        Language.language(forCode: selectedLanguageCode)
    }

    var body: some View {
        Button {
            showingModal = true
        } label: {
            HStack(spacing: style == .toolbar ? 4 : 6) {
                Image(systemName: "globe")
                    .font(style == .toolbar ? .body.weight(.semibold) : .headline)
                Text(language.flag)
                    .font(style == .toolbar ? .body : .headline)
                Text(language.name)
                    .font(style == .toolbar ? .caption.weight(.medium) : .subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(.horizontal, style == .toolbar ? 10 : 14)
            .padding(.vertical, style == .toolbar ? 8 : 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: style == .toolbar ? 16 : 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(VikaL10n.t(.languageModalTitle, languageCode: selectedLanguageCode))
        .sheet(isPresented: $showingModal) {
            LanguageSelectionModal()
        }
    }
}

struct LanguageSelectionModal: View {
    @AppStorage("selectedLanguage") private var selectedLanguageCode = "en"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(Language.allLanguages) { language in
                Button {
                    selectedLanguageCode = language.code
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text(language.flag)
                            .font(.title2)
                        Text(language.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if language.code == selectedLanguageCode {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.appGreen)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .navigationTitle(VikaL10n.t(.languageModalTitle, languageCode: selectedLanguageCode))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview("Button") {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        LanguagePickerButton()
    }
}

#Preview("Modal") {
    LanguageSelectionModal()
}
