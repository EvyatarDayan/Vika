//
//  MessagesAppState.swift
//  Vika — app-level messaging cache + navigation hooks (SpectRoom-compatible).
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class MessagesAppState: ObservableObject {
    @Published var cachedMessageConversations: [MessageDisplay] = []

    @Published var conversationToOpenSenderId: String?
    var currentlyOpenConversationSenderId: String?

    /// In-app “new message” sheet (SpectRoom `NewMessageNotificationModal` parity).
    @Published var showingNewMessageNotification = false
    @Published var newMessageSenderName = ""
    @Published var newMessageSenderPhotoURL: String?
    @Published var newMessageSenderId = ""

    let newMessageReceivedPublisher = PassthroughSubject<MessageDisplay, Never>()

    private var conversationMessagesCache: [String: [MessageDisplay]] = [:]

    // MARK: - Firestore incomingMessages observer (SpectRoom `listenForNewMessages` parity)

    private var incomingListenerRegistration: ListenerRegistration?
    private var inboxInitialLoadDone = false

    func getCachedOrFreshConversations() async throws -> [MessageDisplay] {
        try await refreshMessageConversationsCache()
    }

    func refreshMessageConversationsCache() async throws -> [MessageDisplay] {
        let list = try await FirebaseAuthService.shared.loadInboxConversations()
        cachedMessageConversations = list
        return list
    }

    func dismissNewMessageNotification() {
        showingNewMessageNotification = false
        newMessageSenderName = ""
        newMessageSenderPhotoURL = nil
        newMessageSenderId = ""
    }

    /// Observe `users/{uid}/incomingMessages` so we detect new unread messages and can show the modal + refresh the list.
    func startInboxListener() {
        stopInboxListener()
        guard let myUid = Auth.auth().currentUser?.uid else { return }

        inboxInitialLoadDone = false

        let ref = Firestore.firestore().collection("users").document(myUid).collection("incomingMessages")
        incomingListenerRegistration = ref.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            Task { @MainActor in
                await self.handleIncomingMessagesSnapshot(snapshot, error: error, myUid: myUid)
            }
        }
    }

    func stopInboxListener() {
        incomingListenerRegistration?.remove()
        incomingListenerRegistration = nil
        inboxInitialLoadDone = false
    }

    private func handleIncomingMessagesSnapshot(_ snapshot: QuerySnapshot?, error: Error?, myUid: String) async {
        if error != nil { return }
        guard let snapshot else { return }

        if !inboxInitialLoadDone {
            inboxInitialLoadDone = true
            _ = try? await refreshMessageConversationsCache()
            return
        }

        for change in snapshot.documentChanges {
            guard change.type == .added else { continue }
            let data = change.document.data()
            let senderId = data["senderId"] as? String ?? ""
            let isRead = data["isRead"] as? Bool ?? false
            guard senderId != myUid, !isRead else { continue }

            let conversationOpen = (currentlyOpenConversationSenderId == senderId)
            if !conversationOpen && !showingNewMessageNotification {
                let displayName = (try? await FirebaseAuthService.shared.fetchDisplayName(for: senderId)) ?? "User"
                let photo = try? await FirebaseAuthService.shared.fetchUserProfilePhotoURL(for: senderId)
                newMessageSenderId = senderId
                newMessageSenderName = displayName
                newMessageSenderPhotoURL = photo
                showingNewMessageNotification = true

                Task {
                    if let latest = try? await FirebaseAuthService.shared.fetchLatestMessageFromSender(senderId: senderId) {
                        await MainActor.run {
                            self.updateConversationInCache(latest)
                        }
                    }
                }
            }
        }

        _ = try? await refreshMessageConversationsCache()
    }

    func getCachedConversationMessages(for otherUserId: String) -> [MessageDisplay]? {
        conversationMessagesCache[otherUserId]
    }

    func cacheConversationMessages(_ messages: [MessageDisplay], for otherUserId: String) {
        conversationMessagesCache[otherUserId] = messages
    }

    func updateConversationMessagesCache(_ messages: [MessageDisplay], for otherUserId: String) {
        conversationMessagesCache[otherUserId] = messages
    }

    func updateConversationInCache(_ message: MessageDisplay) {
        var list = cachedMessageConversations
        let other = message.senderName == MessageSenderLabel.currentUser ? message.recipientId : message.senderId
        if let idx = list.firstIndex(where: {
            let o = $0.senderName == MessageSenderLabel.currentUser ? $0.recipientId : $0.senderId
            return o == other
        }) {
            list[idx] = message
        } else {
            list.append(message)
        }
        cachedMessageConversations = list.sorted { $0.createdAt > $1.createdAt }
        newMessageReceivedPublisher.send(message)
    }
}
