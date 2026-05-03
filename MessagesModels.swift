//
//  MessagesModels.swift
//  Vika
//

import Foundation
import SwiftUI

/// Label used for the current user in `MessageDisplay.senderName` (matches SpectRoom / Firebase helpers).
enum MessageSenderLabel {
    static let currentUser = "You"
}

enum MessageType: String, Codable, Equatable {
    case text
    case image
    case voice
}

struct Message: Identifiable, Equatable {
    let id: String
    let conversationId: UUID
    let senderId: UUID
    let senderFirebaseId: String
    let content: String
    let type: MessageType
    let createdAt: Date
    let voiceDuration: TimeInterval?

    init(
        id: String = UUID().uuidString,
        conversationId: UUID = UUID(),
        senderId: UUID = UUID(),
        senderFirebaseId: String,
        content: String,
        type: MessageType,
        createdAt: Date,
        voiceDuration: TimeInterval? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderFirebaseId = senderFirebaseId
        self.content = content
        self.type = type
        self.createdAt = createdAt
        self.voiceDuration = voiceDuration
    }
}

struct MessageDisplay: Identifiable, Equatable {
    let id: String
    let message: Message
    let senderName: String
    let recipientName: String
    let senderId: String
    let recipientId: String
    let senderProfilePhotoURL: String?
    let recipientProfilePhotoURL: String?

    var messageType: MessageType { message.type }
    var content: String { message.content }
    var createdAt: Date { message.createdAt }
    var voiceDuration: TimeInterval? { message.voiceDuration }

    init(
        id: String? = nil,
        message: Message,
        senderName: String,
        recipientName: String,
        senderId: String,
        recipientId: String,
        senderProfilePhotoURL: String?,
        recipientProfilePhotoURL: String?
    ) {
        self.id = id ?? message.id
        self.message = message
        self.senderName = senderName
        self.recipientName = recipientName
        self.senderId = senderId
        self.recipientId = recipientId
        self.senderProfilePhotoURL = senderProfilePhotoURL
        self.recipientProfilePhotoURL = recipientProfilePhotoURL
    }

    init(message: Message, senderName: String, recipientName: String, senderId: String, recipientId: String, senderProfilePhotoURL: String?, recipientProfilePhotoURL: String?) {
        self.init(id: message.id, message: message, senderName: senderName, recipientName: recipientName, senderId: senderId, recipientId: recipientId, senderProfilePhotoURL: senderProfilePhotoURL, recipientProfilePhotoURL: recipientProfilePhotoURL)
    }
}

// MARK: - Date formatting (messages UI)

extension Date {
    func messagesTimeAgoDisplay(languageCode: String) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: languageCode)
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    func messagesFormattedTimestamp(languageCode: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageCode)
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        if Calendar.current.isDateInToday(self) {
            return formatter.string(from: self)
        }
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Localization environment

private enum MessagesLanguageKey: EnvironmentKey {
    static let defaultValue = "en"
}

extension EnvironmentValues {
    var messagesLanguageCode: String {
        get { self[MessagesLanguageKey.self] }
        set { self[MessagesLanguageKey.self] = newValue }
    }
}

/// Alias so ported SpectRoom views can keep `@EnvironmentObject var appState: AppStateManager`.
typealias AppStateManager = MessagesAppState
