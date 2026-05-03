//
//  MessagingService.swift
//  Vika — Firestore messaging (SpectRoom: sentMessages + incomingMessages) + RTDB user profiles.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

// MARK: - FirebaseAuthService (SpectRoom-compatible surface for Messages UI)

final class FirebaseAuthService {
    static let shared = FirebaseAuthService()

    let auth: Auth
    private let usersRef: DatabaseReference

    private init() {
        auth = Auth.auth()
        usersRef = Database.database().reference().child("users")
    }

    var isAuthenticated: Bool { auth.currentUser != nil }

    func updateUserData(_ values: [String: Any]) async throws {
        guard let uid = auth.currentUser?.uid else { return }
        try await updateChildValues(values, at: usersRef.child(uid))
    }

    func fetchUserProfilePhotoURL(for uid: String) async throws -> String? {
        let snap = try await getData(at: usersRef.child(uid))
        guard let dict = snap.value as? [String: Any],
              let url = dict["profileImageURL"] as? String,
              !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return url
    }

    func fetchDisplayName(for uid: String) async throws -> String {
        let snap = try await getData(at: usersRef.child(uid))
        guard let dict = snap.value as? [String: Any] else { return "User" }
        let first = dict["firstName"] as? String ?? ""
        let last = dict["lastName"] as? String ?? ""
        let name = "\(first) \(last)".trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { return name }
        return dict["email"] as? String ?? "User"
    }

    func markMessagesAsRead(from otherUserId: String) async throws {
        guard let myUid = auth.currentUser?.uid else { return }
        try await SpectRoomFirestoreMessaging.markMessagesAsRead(myUid: myUid, from: otherUserId)
    }

    func fetchConversationMessages(with otherUserId: String) async throws -> [Message] {
        guard let myUid = auth.currentUser?.uid else { return [] }
        return try await SpectRoomFirestoreMessaging.fetchConversationMessages(myUid: myUid, otherUserId: otherUserId)
    }

    func fetchConversationMessagesContentOnly(with otherUserId: String) async throws -> [Message] {
        guard let myUid = auth.currentUser?.uid else { return [] }
        return try await SpectRoomFirestoreMessaging.fetchConversationMessagesContentOnly(myUid: myUid, otherUserId: otherUserId)
    }

    func sendMessage(to recipientId: String, content: String) async throws -> String {
        guard let myUid = auth.currentUser?.uid else {
            throw NSError(domain: "Messaging", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }
        return try await SpectRoomFirestoreMessaging.sendTextMessage(from: myUid, to: recipientId, content: content)
    }

    func sendImageMessage(to recipientId: String, imageURL: String) async throws -> String {
        guard let myUid = auth.currentUser?.uid else {
            throw NSError(domain: "Messaging", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }
        return try await SpectRoomFirestoreMessaging.sendImageMessage(from: myUid, to: recipientId, imageURL: imageURL)
    }

    func sendVoiceMessage(to recipientId: String, audioURL: String, duration: TimeInterval) async throws -> String {
        guard let myUid = auth.currentUser?.uid else {
            throw NSError(domain: "Messaging", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }
        return try await SpectRoomFirestoreMessaging.sendVoiceMessage(from: myUid, to: recipientId, audioURL: audioURL, duration: duration)
    }

    /// If there is no message history with `otherUserId`, sends `initialBody` as the first message (creates chat + inbox for both users).
    func ensureStarterConversation(with otherUserId: String, initialBody: String) async throws {
        guard auth.currentUser != nil else {
            throw NSError(domain: "Messaging", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }
        let existing = try await fetchConversationMessages(with: otherUserId)
        guard existing.isEmpty else { return }
        _ = try await sendMessage(to: otherUserId, content: initialBody)
    }

    func fetchLatestMessageFromSender(senderId: String) async throws -> MessageDisplay? {
        guard let myUid = auth.currentUser?.uid else { return nil }
        return try await SpectRoomFirestoreMessaging.fetchLatestMessageFromSender(
            myUid: myUid,
            senderId: senderId,
            fetchDisplayName: { try await self.fetchDisplayName(for: $0) },
            fetchPhoto: { try await self.fetchUserProfilePhotoURL(for: $0) }
        )
    }

    /// Conversation shell when there is no message history yet (e.g. user tapped Message on a favorite).
    func makePlaceholderConversationDisplay(with otherUserId: String) async throws -> MessageDisplay {
        guard let myUid = auth.currentUser?.uid else {
            throw NSError(domain: "Messaging", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }
        let otherName = (try? await fetchDisplayName(for: otherUserId)) ?? "User"
        let otherPhoto = try? await fetchUserProfilePhotoURL(for: otherUserId)
        let myPhoto = try? await fetchUserProfilePhotoURL(for: myUid)
        let placeholder = Message(
            id: "new-thread-\(otherUserId)",
            senderFirebaseId: myUid,
            content: "",
            type: .text,
            createdAt: Date(),
            voiceDuration: nil
        )
        return MessageDisplay(
            message: placeholder,
            senderName: MessageSenderLabel.currentUser,
            recipientName: otherName,
            senderId: myUid,
            recipientId: otherUserId,
            senderProfilePhotoURL: myPhoto,
            recipientProfilePhotoURL: otherPhoto
        )
    }

    func loadInboxConversations() async throws -> [MessageDisplay] {
        guard let myUid = auth.currentUser?.uid else { return [] }
        return try await SpectRoomFirestoreMessaging.fetchLatestMessagesFromEachUser(
            myUid: myUid,
            fetchDisplayName: { try await self.fetchDisplayName(for: $0) },
            fetchPhoto: { try await self.fetchUserProfilePhotoURL(for: $0) }
        )
    }

    private func updateChildValues(_ values: [AnyHashable: Any], at ref: DatabaseReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.updateChildValues(values) { error, _ in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: ()) }
            }
        }
    }

    private func getData(at ref: DatabaseReference) async throws -> DataSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            ref.getData { error, snapshot in
                if let error { continuation.resume(throwing: error); return }
                guard let snapshot else {
                    continuation.resume(throwing: NSError(domain: "Messaging", code: -2))
                    return
                }
                continuation.resume(returning: snapshot)
            }
        }
    }
}

// MARK: - Photo / voice uploads (SpectRoom-compatible names)

final class PhotoStorageService {
    static let shared = PhotoStorageService()

    private let storage = Storage.storage().reference().child("messageMedia")

    func uploadMessageImage(_ image: UIImage, for uid: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "PhotoStorage", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
        }
        let name = "\(UUID().uuidString).jpg"
        let ref = storage.child(uid).child(name)
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        _ = try await putData(data, ref: ref, metadata: meta)
        return try await downloadURL(ref: ref)
    }

    func uploadVoiceMessage(_ fileURL: URL, for uid: String) async throws -> String {
        let data = try Data(contentsOf: fileURL)
        let name = "voice/\(UUID().uuidString).m4a"
        let ref = storage.child(uid).child(name)
        let meta = StorageMetadata()
        meta.contentType = "audio/m4a"
        _ = try await putData(data, ref: ref, metadata: meta)
        return try await downloadURL(ref: ref)
    }

    private func putData(_ data: Data, ref: StorageReference, metadata: StorageMetadata) async throws -> StorageMetadata {
        try await withCheckedThrowingContinuation { continuation in
            ref.putData(data, metadata: metadata) { meta, error in
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: meta ?? StorageMetadata())
            }
        }
    }

    private func downloadURL(ref: StorageReference) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            ref.downloadURL { url, error in
                if let error { continuation.resume(throwing: error); return }
                guard let url else {
                    continuation.resume(throwing: NSError(domain: "PhotoStorage", code: -3))
                    return
                }
                continuation.resume(returning: url.absoluteString)
            }
        }
    }
}
