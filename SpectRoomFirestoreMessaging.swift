//
//  SpectRoomFirestoreMessaging.swift
//  Vika — Firestore messaging (same model as SpectRoom: sentMessages + incomingMessages).
//

import FirebaseFirestore
import Foundation

/// Mirrors SpectRoom `FirebaseAuthService` messaging: `users/{uid}/sentMessages`, `users/{uid}/incomingMessages`.
enum SpectRoomFirestoreMessaging {
    private static var db: Firestore { Firestore.firestore() }

    // MARK: - Send

    static func sendTextMessage(from myUid: String, to recipientId: String, content: String) async throws -> String {
        let messageId = UUID().uuidString
        let timestamp = Date().timeIntervalSince1970
        let messageData: [String: Any] = [
            "id": messageId,
            "senderId": myUid,
            "recipientId": recipientId,
            "content": content,
            "type": MessageType.text.rawValue,
            "createdAt": timestamp,
            "isRead": false,
            "readAt": NSNull()
        ]
        let senderRef = db.collection("users").document(myUid).collection("sentMessages").document(messageId)
        let recipientRef = db.collection("users").document(recipientId).collection("incomingMessages").document(messageId)
        try await senderRef.setData(messageData)
        try await recipientRef.setData(messageData)
        return messageId
    }

    static func sendImageMessage(from myUid: String, to recipientId: String, imageURL: String) async throws -> String {
        let messageId = UUID().uuidString
        let timestamp = Date().timeIntervalSince1970
        let messageData: [String: Any] = [
            "id": messageId,
            "senderId": myUid,
            "recipientId": recipientId,
            "content": imageURL,
            "type": MessageType.image.rawValue,
            "createdAt": timestamp,
            "isRead": false,
            "readAt": NSNull()
        ]
        let senderRef = db.collection("users").document(myUid).collection("sentMessages").document(messageId)
        let recipientRef = db.collection("users").document(recipientId).collection("incomingMessages").document(messageId)
        try await senderRef.setData(messageData)
        try await recipientRef.setData(messageData)
        return messageId
    }

    static func sendVoiceMessage(from myUid: String, to recipientId: String, audioURL: String, duration: TimeInterval) async throws -> String {
        let messageId = UUID().uuidString
        let timestamp = Date().timeIntervalSince1970
        let messageData: [String: Any] = [
            "id": messageId,
            "senderId": myUid,
            "recipientId": recipientId,
            "content": audioURL,
            "type": MessageType.voice.rawValue,
            "voiceDuration": duration,
            "createdAt": timestamp,
            "isRead": false,
            "readAt": NSNull()
        ]
        let senderRef = db.collection("users").document(myUid).collection("sentMessages").document(messageId)
        let recipientRef = db.collection("users").document(recipientId).collection("incomingMessages").document(messageId)
        try await senderRef.setData(messageData)
        try await recipientRef.setData(messageData)
        return messageId
    }

    // MARK: - Read / merge thread (SpectRoom `fetchConversationMessages`)

    static func fetchConversationMessages(myUid: String, otherUserId: String) async throws -> [Message] {
        var all: [Message] = []

        let sentSnap = try await db.collection("users").document(myUid).collection("sentMessages").getDocuments()
        for doc in sentSnap.documents {
            let data = doc.data()
            guard let recipientId = data["recipientId"] as? String, recipientId == otherUserId else { continue }
            if let m = messageFromFirestoreDoc(id: doc.documentID, data: data) { all.append(m) }
        }

        let incomingSnap = try await db.collection("users").document(myUid).collection("incomingMessages").getDocuments()
        for doc in incomingSnap.documents {
            let data = doc.data()
            guard let senderId = data["senderId"] as? String, senderId == otherUserId else { continue }
            if let m = messageFromFirestoreDoc(id: doc.documentID, data: data) { all.append(m) }
        }

        all.sort { $0.createdAt < $1.createdAt }
        return all
    }

    /// Same as `fetchConversationMessages` but only raw `Message` bodies (SpectRoom `fetchConversationMessagesContentOnly`).
    static func fetchConversationMessagesContentOnly(myUid: String, otherUserId: String) async throws -> [Message] {
        try await fetchConversationMessages(myUid: myUid, otherUserId: otherUserId)
    }

    // MARK: - Inbox list (SpectRoom `fetchLatestMessagesFromEachUser`)

    static func fetchLatestMessagesFromEachUser(myUid: String, fetchDisplayName: (String) async throws -> String, fetchPhoto: (String) async throws -> String?) async throws -> [MessageDisplay] {
        var userLatest: [String: MessageDisplay] = [:]

        let sentSnap = try await db.collection("users").document(myUid).collection("sentMessages").getDocuments()
        for doc in sentSnap.documents {
            let data = doc.data()
            guard let senderId = data["senderId"] as? String,
                  let recipientId = data["recipientId"] as? String else { continue }
            guard let m = messageFromFirestoreDoc(id: doc.documentID, data: data) else { continue }

            let recipientName = try await fetchDisplayName(recipientId)
            let recipientPhoto = try await fetchPhoto(recipientId)
            let display = MessageDisplay(
                message: m,
                senderName: MessageSenderLabel.currentUser,
                recipientName: recipientName,
                senderId: senderId,
                recipientId: recipientId,
                senderProfilePhotoURL: nil,
                recipientProfilePhotoURL: recipientPhoto
            )

            if let existing = userLatest[recipientId] {
                if display.createdAt > existing.createdAt { userLatest[recipientId] = display }
            } else {
                userLatest[recipientId] = display
            }
        }

        let incomingSnap = try await db.collection("users").document(myUid).collection("incomingMessages").getDocuments()
        for doc in incomingSnap.documents {
            let data = doc.data()
            guard let senderId = data["senderId"] as? String,
                  let recipientId = data["recipientId"] as? String else { continue }
            guard let m = messageFromFirestoreDoc(id: doc.documentID, data: data) else { continue }

            let senderName = try await fetchDisplayName(senderId)
            let senderPhoto = try await fetchPhoto(senderId)
            let display = MessageDisplay(
                message: m,
                senderName: senderName,
                recipientName: MessageSenderLabel.currentUser,
                senderId: senderId,
                recipientId: recipientId,
                senderProfilePhotoURL: senderPhoto,
                recipientProfilePhotoURL: nil
            )

            if let existing = userLatest[senderId] {
                if display.createdAt > existing.createdAt { userLatest[senderId] = display }
            } else {
                userLatest[senderId] = display
            }
        }

        return Array(userLatest.values).sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Latest from sender (notifications / open thread)

    static func fetchLatestMessageFromSender(myUid: String, senderId: String, fetchDisplayName: (String) async throws -> String, fetchPhoto: (String) async throws -> String?) async throws -> MessageDisplay? {
        let incomingRef = db.collection("users").document(myUid).collection("incomingMessages")
        let snapshot = try await incomingRef
            .whereField("senderId", isEqualTo: senderId)
            .order(by: "createdAt", descending: true)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first else { return nil }
        let data = doc.data()
        guard let m = messageFromFirestoreDoc(id: doc.documentID, data: data) else { return nil }

        let senderName = try await fetchDisplayName(senderId)
        let senderPhoto = try await fetchPhoto(senderId)
        return MessageDisplay(
            message: m,
            senderName: senderName,
            recipientName: MessageSenderLabel.currentUser,
            senderId: senderId,
            recipientId: myUid,
            senderProfilePhotoURL: senderPhoto,
            recipientProfilePhotoURL: nil
        )
    }

    // MARK: - Mark read (SpectRoom `markMessagesAsRead`)

    static func markMessagesAsRead(myUid: String, from otherUserId: String) async throws {
        let incomingRef = db.collection("users").document(myUid).collection("incomingMessages")
        let snapshot = try await incomingRef.whereField("senderId", isEqualTo: otherUserId).getDocuments()
        let batch = db.batch()
        let readAt = Date().timeIntervalSince1970
        for doc in snapshot.documents {
            let data = doc.data()
            let isRead = data["isRead"] as? Bool ?? false
            if !isRead {
                batch.updateData(["isRead": true, "readAt": readAt], forDocument: doc.reference)
            }
        }
        try await batch.commit()
    }

    // MARK: - Helpers

    private static func messageFromFirestoreDoc(id: String, data: [String: Any]) -> Message? {
        guard let senderId = data["senderId"] as? String,
              let content = data["content"] as? String,
              let createdAt = parseCreatedAt(data["createdAt"]) else { return nil }
        let typeRaw = data["type"] as? String ?? MessageType.text.rawValue
        let type = MessageType(rawValue: typeRaw) ?? .text
        let voiceDur = data["voiceDuration"] as? TimeInterval
        let senderUUID = UUID(uuidString: senderId) ?? UUID()
        return Message(
            id: id,
            conversationId: UUID(),
            senderId: senderUUID,
            senderFirebaseId: senderId,
            content: content,
            type: type,
            createdAt: createdAt,
            voiceDuration: voiceDur
        )
    }

    private static func parseCreatedAt(_ value: Any?) -> Date? {
        if let ts = value as? Timestamp {
            return ts.dateValue()
        }
        if let d = value as? Double {
            return Date(timeIntervalSince1970: d)
        }
        if let n = value as? Int {
            return Date(timeIntervalSince1970: TimeInterval(n))
        }
        if let n = value as? NSNumber {
            return Date(timeIntervalSince1970: n.doubleValue)
        }
        return nil
    }
}
