//
//  NewMessageNotificationModal.swift
//  Vika
//

import SwiftUI

struct NewMessageNotificationModal: View {
    let senderName: String
    let senderProfilePhotoURL: String?
    let onOpen: () -> Void
    let onLater: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.messagesLanguageCode) private var languageCode

    private func t(_ key: VikaL10n.Key) -> String {
        VikaL10n.t(key, languageCode: languageCode)
    }

    var body: some View {
        let modalBackgroundColor = colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color(.systemGroupedBackground)

        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onLater() }

            VStack(spacing: 20) {
                CachedAsyncImage(url: URL(string: senderProfilePhotoURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                )

                VStack(spacing: 12) {
                    Text(t(.messagesNotificationTitle))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? Color.gray : Color.black)

                    Text(String(format: t(.messagesNotificationFrom), senderName))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                VStack(spacing: 12) {
                    Button(action: onOpen) {
                        Text(t(.messagesNotificationOpen))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.appGreen)
                            )
                    }
                    .padding(.horizontal, 20)

                    Button(action: onLater) {
                        Text(t(.messagesNotificationLater))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray)
                            )
                    }
                    .padding(.horizontal, 20)
                }
            }
            .frame(maxWidth: 280)
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(modalBackgroundColor)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 16)
        }
        .ignoresSafeArea(.all, edges: .all)
    }
}

#Preview {
    NewMessageNotificationModal(
        senderName: "Sarah",
        senderProfilePhotoURL: nil,
        onOpen: {},
        onLater: {}
    )
    .environment(\.messagesLanguageCode, "en")
}
