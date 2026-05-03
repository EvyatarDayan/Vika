//
//  PreMessageOptionsModal.swift
//  Vika
//

import SwiftUI

struct PreMessageOptionsModal: View {
    let profileName: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.messagesLanguageCode) private var languageCode

    private func t(_ key: VikaL10n.Key) -> String {
        VikaL10n.t(key, languageCode: languageCode)
    }

    private var options: [String] {
        [
            String(format: "Hi %@ — are you available this week?", profileName),
            "Thanks for helping with the laundry.",
            "Could we schedule a pickup?",
            "What are your current rates?",
        ]
    }

    var body: some View {
        NavigationStack {
            List(options, id: \.self) { line in
                Button(line) {
                    onSelect(line)
                }
            }
            .navigationTitle(t(.matchesPreMessageButton))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t(.commonClose)) {
                        dismiss()
                    }
                }
            }
        }
    }
}
