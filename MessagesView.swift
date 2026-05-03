//
//  MessagesView.swift
//  Vika
//

import FirebaseAuth
import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var appState: AppStateManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.messagesLanguageCode) private var languageCode
    @Binding var selectedTab: Int

    @State private var conversations: [MessageDisplay] = []
    @State private var isLoading = true
    @State private var showingMessageModal = false
    @State private var selectedMessage: MessageDisplay?
    @State private var conversationMessages: [MessageDisplay] = []

    private func t(_ key: VikaL10n.Key) -> String {
        VikaL10n.t(key, languageCode: languageCode)
    }

    /// Non-persistent preview row so the empty state shows what a conversation looks like.
    private var sampleConversationDisplay: MessageDisplay {
        let myUid = FirebaseAuthService.shared.auth.currentUser?.uid ?? "local"
        let msg = Message(
            id: "sample-preview",
            senderFirebaseId: "sample",
            content: t(.messagesSampleBody),
            type: .text,
            createdAt: Date(),
            voiceDuration: nil
        )
        return MessageDisplay(
            message: msg,
            senderName: t(.messagesSampleFolderName),
            recipientName: MessageSenderLabel.currentUser,
            senderId: "sample",
            recipientId: myUid,
            senderProfilePhotoURL: nil,
            recipientProfilePhotoURL: nil
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                VStack(spacing: 20) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(t(.messagesLoading))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(backgroundImage)
            } else if conversations.isEmpty {
                VStack {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "message")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.6))
                        Text(t(.messagesEmpty))
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text(t(.messagesEmptyDescription))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(t(.messagesSampleCaption))
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            ConversationRow(conversation: sampleConversationDisplay, languageCode: languageCode) {}
                                .allowsHitTesting(false)
                                .opacity(0.95)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        Button {
                            selectedTab = 2
                        } label: {
                            Text(t(.messagesStartBrowsing))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.appGreen)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 30)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(backgroundImage)
            } else {
                List(conversations) { conversation in
                    ConversationRow(conversation: conversation, languageCode: languageCode) {
                        handleConversationTap(conversation)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(backgroundImage)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(t(.messagesTitle))
                    .font(.system(size: 28, weight: .bold))
            }
        }
        .onReceive(appState.$cachedMessageConversations) { updated in
            conversations = sortedConversations(updated)
            if isLoading { isLoading = false }
        }
        .onReceive(appState.newMessageReceivedPublisher) { _ in
            conversations = sortedConversations(appState.cachedMessageConversations)
        }
        .onAppear {
            loadConversationsFromCache()
            if let senderId = appState.conversationToOpenSenderId, !senderId.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if appState.conversationToOpenSenderId == senderId {
                        openConversationForSender(senderId: senderId)
                    }
                }
            }
        }
        .onChange(of: appState.conversationToOpenSenderId) { _, senderId in
            if let senderId, !senderId.isEmpty {
                if conversations.isEmpty {
                    loadConversations()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if appState.conversationToOpenSenderId == senderId {
                        openConversationForSender(senderId: senderId)
                    }
                }
            }
        }
        .onChange(of: conversations.count) { _, count in
            if let senderId = appState.conversationToOpenSenderId, !senderId.isEmpty, count > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if appState.conversationToOpenSenderId == senderId {
                        openConversationForSender(senderId: senderId)
                    }
                }
            }
        }
        .onChange(of: isLoading) { _, loading in
            if !loading, let senderId = appState.conversationToOpenSenderId, !senderId.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    if appState.conversationToOpenSenderId == senderId {
                        openConversationForSender(senderId: senderId)
                    }
                }
            }
        }
        .sheet(isPresented: $showingMessageModal) {
            if let message = selectedMessage {
                MessageConversationModal(message: message, conversationMessages: $conversationMessages)
                    .interactiveDismissDisabled()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            } else {
                VStack(spacing: 16) {
                    Text(t(.messagesErrorNoMessage))
                        .foregroundColor(.red)
                    Button(t(.commonClose)) {
                        showingMessageModal = false
                    }
                }
            }
        }
        .onChange(of: showingMessageModal) { _, newValue in
            if newValue, let message = selectedMessage {
                let otherUserId = message.senderName == MessageSenderLabel.currentUser ? message.recipientId : message.senderId
                appState.currentlyOpenConversationSenderId = otherUserId
                if message.senderName != MessageSenderLabel.currentUser {
                    Task {
                        try? await FirebaseAuthService.shared.markMessagesAsRead(from: otherUserId)
                    }
                }
                Task {
                    await updateConversationOpenState(userId: otherUserId, isOpen: true)
                }
            } else {
                let previousUserId = appState.currentlyOpenConversationSenderId
                appState.currentlyOpenConversationSenderId = nil
                if let userId = previousUserId {
                    Task {
                        await updateConversationOpenState(userId: userId, isOpen: false)
                    }
                }
                DispatchQueue.main.async {
                    self.loadConversations()
                }
            }
        }
    }

    private var backgroundImage: some View {
        Image(colorScheme == .dark ? "ColorsDark" : "Colors")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .ignoresSafeArea()
    }

    private func updateConversationOpenState(userId: String, isOpen: Bool) async {
        guard FirebaseAuthService.shared.auth.currentUser?.uid != nil else { return }
        do {
            let state: [String: Any] = [
                "openConversationUserId": isOpen ? userId : NSNull(),
                "updatedAt": Date().timeIntervalSince1970
            ]
            try await FirebaseAuthService.shared.updateUserData(state)
        } catch {
            // Non-fatal for messaging UX.
        }
    }

    private func loadConversationsFromCache() {
        guard FirebaseAuthService.shared.isAuthenticated else { return }
        if conversations.isEmpty { isLoading = true }

        Task {
            do {
                let cachedOrFresh = try await appState.getCachedOrFreshConversations()
                await MainActor.run {
                    conversations = sortedConversations(cachedOrFresh)
                    isLoading = false
                }
                Task {
                    do {
                        let refreshed = try await appState.refreshMessageConversationsCache()
                        await MainActor.run {
                            if refreshed.count != conversations.count {
                                conversations = sortedConversations(refreshed)
                            } else {
                                var updated = false
                                for refreshedConv in refreshed {
                                    if let existingIndex = conversations.firstIndex(where: { conv in
                                        let otherUserId = conv.senderName == MessageSenderLabel.currentUser ? conv.recipientId : conv.senderId
                                        let newOtherUserId = refreshedConv.senderName == MessageSenderLabel.currentUser ? refreshedConv.recipientId : refreshedConv.senderId
                                        return otherUserId == newOtherUserId
                                    }) {
                                        if refreshedConv.createdAt > conversations[existingIndex].createdAt {
                                            conversations[existingIndex] = refreshedConv
                                            updated = true
                                        }
                                    }
                                }
                                if updated {
                                    conversations = sortedConversations(conversations)
                                }
                            }
                        }
                    } catch {}
                }
            } catch {
                await MainActor.run {
                    conversations = []
                    isLoading = false
                }
            }
        }
    }

    private func loadConversations() {
        loadConversationsFromCache()
    }

    private func sortedConversations(_ list: [MessageDisplay]) -> [MessageDisplay] {
        list.sorted { $0.createdAt > $1.createdAt }
    }

    private func handleConversationTap(_ conversation: MessageDisplay) {
        selectedMessage = conversation
        let otherUserId = conversation.senderName == MessageSenderLabel.currentUser ? conversation.recipientId : conversation.senderId
        appState.currentlyOpenConversationSenderId = otherUserId
        showingMessageModal = true
    }

    /// Opens the thread sheet for `senderId`. Waits for inbox load to finish, then matches list row or builds placeholder (new thread).
    private func openConversationForSender(senderId: String, loadingWaitCount: Int = 0) {
        if isLoading && loadingWaitCount < 60 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                if appState.conversationToOpenSenderId == senderId {
                    openConversationForSender(senderId: senderId, loadingWaitCount: loadingWaitCount + 1)
                }
            }
            return
        }

        if let conversation = conversations.first(where: { conv in
            let otherUserId = conv.senderName == MessageSenderLabel.currentUser ? conv.recipientId : conv.senderId
            return otherUserId == senderId
        }) {
            selectedMessage = conversation
            appState.currentlyOpenConversationSenderId = senderId
            Task {
                await updateConversationOpenState(userId: senderId, isOpen: true)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if selectedMessage != nil {
                    showingMessageModal = true
                    appState.conversationToOpenSenderId = nil
                    appState.newMessageSenderName = ""
                    appState.newMessageSenderPhotoURL = nil
                    appState.newMessageSenderId = ""
                }
            }
            return
        }

        Task {
            await fetchAndCreateConversationForSender(senderId: senderId)
        }
    }

    private func fetchAndCreateConversationForSender(senderId: String) async {
        if let messageDisplay = try? await FirebaseAuthService.shared.fetchLatestMessageFromSender(senderId: senderId) {
            await MainActor.run {
                presentConversationSheet(senderId: senderId, message: messageDisplay)
            }
            return
        }
        if let placeholder = try? await FirebaseAuthService.shared.makePlaceholderConversationDisplay(with: senderId) {
            await MainActor.run {
                presentConversationSheet(senderId: senderId, message: placeholder)
            }
            return
        }
        await MainActor.run {
            appState.conversationToOpenSenderId = nil
            appState.newMessageSenderName = ""
            appState.newMessageSenderPhotoURL = nil
            appState.newMessageSenderId = ""
        }
    }

    private func presentConversationSheet(senderId: String, message: MessageDisplay) {
        selectedMessage = message
        appState.currentlyOpenConversationSenderId = senderId
        Task {
            await updateConversationOpenState(userId: senderId, isOpen: true)
        }
        showingMessageModal = true
        appState.conversationToOpenSenderId = nil
        appState.newMessageSenderName = ""
        appState.newMessageSenderPhotoURL = nil
        appState.newMessageSenderId = ""
    }
}

struct ConversationRow: View {
    let conversation: MessageDisplay
    let languageCode: String
    let onTap: () -> Void

    private func t(_ key: VikaL10n.Key) -> String {
        VikaL10n.t(key, languageCode: languageCode)
    }

    var body: some View {
        HStack(spacing: 12) {
            if let profilePhotoURL = otherUserProfilePhotoURL, !profilePhotoURL.isEmpty {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        CachedAsyncImage(url: URL(string: profilePhotoURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.appGreen.opacity(0.2))
                                .overlay(
                                    Text(String(otherUserName.prefix(1)).uppercased())
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.appGreen)
                                )
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .fill(Color.appGreen.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(String(otherUserName.prefix(1)).uppercased())
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.appGreen)
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(otherUserName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(conversation.createdAt.messagesTimeAgoDisplay(languageCode: languageCode))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text(previewText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: conversation.senderName == MessageSenderLabel.currentUser ? "paperplane.fill" : "envelope.fill")
                        .foregroundColor(conversation.senderName == MessageSenderLabel.currentUser ? Color.appGreen : .green)
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    private var otherUserName: String {
        if conversation.senderName == MessageSenderLabel.currentUser {
            return conversation.recipientName
        } else {
            return conversation.senderName
        }
    }

    private var otherUserProfilePhotoURL: String? {
        if conversation.senderName == MessageSenderLabel.currentUser {
            return conversation.recipientProfilePhotoURL
        } else {
            return conversation.senderProfilePhotoURL
        }
    }

    private var previewText: String {
        switch conversation.messageType {
        case .image:
            return t(.messagesPreviewPhoto)
        case .voice:
            if let duration = conversation.voiceDuration {
                return String(format: t(.messagesPreviewVoiceDuration), messagesFormattedDuration(duration))
            }
            return t(.messagesPreviewVoice)
        default:
            return conversation.content
        }
    }
}

private func messagesFormattedDuration(_ interval: TimeInterval) -> String {
    guard interval.isFinite, !interval.isNaN else { return "0:00" }
    let total = max(Int(interval.rounded()), 0)
    let minutes = total / 60
    let seconds = total % 60
    return String(format: "%d:%02d", minutes, seconds)
}
