//
//  MessageConversationModal.swift
//  Vika
//

import AVFoundation
import FirebaseAuth
import SwiftUI
import UIKit

struct MessageConversationModal: View {
    let message: MessageDisplay
    @Binding var conversationMessages: [MessageDisplay]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var appState: AppStateManager
    @Environment(\.messagesLanguageCode) private var languageCode

    @FocusState private var isTextFieldFocused: Bool
    @State private var replyText = ""
    @State private var isSendingReply = false
    @State private var isLoadingMessages = true
    @State private var refreshTimer: Timer?
    @State private var currentUserProfilePhotoURL: String?
    @State private var otherUserProfilePhotoURL: String?
    @State private var hasMarkedAsRead = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingConversationPhotoViewer = false
    @State private var selectedPhotoIndex = 0
    @State private var previousMessageCount = 0

    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioRecordingURL: URL?
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var isRecording = false
    @State private var showRecordingPreview = false
    @State private var isSendingVoice = false
    @State private var showingMicrophonePermissionAlert = false
    @State private var showingPreMessageOptions = false

    @State private var otherUserResolvedName: String = ""

    private func t(_ key: VikaL10n.Key) -> String {
        VikaL10n.t(key, languageCode: languageCode)
    }

    var conversationTitle: String {
        if message.senderName == MessageSenderLabel.currentUser {
            return message.recipientName
        } else {
            return message.senderName
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Image(colorScheme == .dark ? "ColorsDark" : "Colors")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 120)

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if isLoadingMessages && conversationMessages.isEmpty {
                                    VStack(spacing: 16) {
                                        ProgressView()
                                            .scaleEffect(1.35)
                                        Text(t(.messagesLoadingConversation))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 48)
                                    .padding(.bottom, 24)
                                } else if !isLoadingMessages && conversationMessages.isEmpty {
                                    Text(t(.messagesNoMessagesFound))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.top, 48)
                                        .padding(.bottom, 24)
                                }

                                ForEach(conversationMessages) { msg in
                                    MessageBubble(
                                        message: msg,
                                        currentUserProfilePhotoURL: currentUserProfilePhotoURL,
                                        otherUserProfilePhotoURL: otherUserProfilePhotoURL,
                                        conversationMessages: conversationMessages,
                                        showingConversationPhotoViewer: $showingConversationPhotoViewer,
                                        selectedPhotoIndex: $selectedPhotoIndex
                                    )
                                    .id(msg.id)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                            .padding(.bottom, 8)
                            .frame(minHeight: 200)
                        }
                        .scrollContentBackground(.hidden)
                        .scrollIndicators(.hidden)
                        // Pin the composer to the conversation: always visible, scroll content lays out above it.
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            messageComposer
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                                .padding(.bottom, 12)
                                .background(.ultraThinMaterial)
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if let lastMessage = conversationMessages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: conversationMessages.count) { _, _ in
                            if let lastMessage = conversationMessages.last {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(conversationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        refreshMessagesOnly()
                        stopAutoRefresh()
                        startAutoRefresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color.appGreen)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(t(.settingsDone)) {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        sendReply()
                    } label: {
                        if isSendingReply {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text(t(.messagesSend))
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingReply)
                    .foregroundColor(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : Color.appGreen)
                }
            }
            .safeAreaInset(edge: .top) {
                HStack {
                    Button {
                        showingPreMessageOptions = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 14))
                            Text(t(.matchesPreMessageButton))
                                .font(.subheadline)
                        }
                        .foregroundColor(Color.appGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.appGreen.opacity(0.12))
                        .cornerRadius(8)
                    }
                    Spacer()
                    Button(t(.settingsDone)) {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(Color.appGreen)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 2)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
            }
            .onAppear {
                let otherUserId = message.senderName == MessageSenderLabel.currentUser ? message.recipientId : message.senderId
                appState.currentlyOpenConversationSenderId = otherUserId
                Task {
                    await updateConversationOpenStateInFirestore(userId: otherUserId, isOpen: true)
                    if otherUserResolvedName.isEmpty {
                        if let n = try? await FirebaseAuthService.shared.fetchDisplayName(for: otherUserId) {
                            await MainActor.run { otherUserResolvedName = n }
                        }
                    }
                }
                loadConversationMessages()
                startAutoRefresh()
            }
            .onChange(of: isLoadingMessages) { _, loading in
                guard !loading else { return }
                // Focus after initial load + sheet transition so the keyboard can appear.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    isTextFieldFocused = true
                }
            }
            .onDisappear {
                let otherUserId = message.senderName == MessageSenderLabel.currentUser ? message.recipientId : message.senderId
                appState.currentlyOpenConversationSenderId = nil
                Task {
                    await updateConversationOpenStateInFirestore(userId: otherUserId, isOpen: false)
                }
                stopAutoRefresh()
            }
            .sheet(isPresented: $showingImagePicker) {
                MessageImagePicker(selectedImage: $selectedImage)
            }
            .onChange(of: selectedImage) { _, newImage in
                if let image = newImage {
                    sendImageMessage(image: image)
                }
            }
            .sheet(isPresented: $showingConversationPhotoViewer) {
                let imageMessages = conversationMessages.filter { $0.messageType == .image }
                let imageURLs = imageMessages.map(\.content)
                ConversationPhotoViewerModal(
                    photos: imageURLs,
                    selectedIndex: $selectedPhotoIndex,
                    conversationMessages: conversationMessages
                )
            }
            .alert(t(.messagesMicrophoneAlertTitle), isPresented: $showingMicrophonePermissionAlert) {
                Button(t(.alertOK), role: .cancel) {}
            } message: {
                Text(t(.messagesMicrophoneAlertMessage))
            }
            .sheet(isPresented: $showingPreMessageOptions) {
                PreMessageOptionsModal(
                    profileName: conversationTitle,
                    onSelect: { selected in
                        replyText = selected
                        showingPreMessageOptions = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isTextFieldFocused = true
                        }
                    }
                )
            }
            .overlay {
                Group {
                    if isRecording {
                        ZStack {
                            Color.black.opacity(0.8)
                                .ignoresSafeArea()
                            RecordingIndicatorView(durationText: modalFormattedDuration(recordingDuration))
                                .padding(.vertical, 20)
                                .padding(.horizontal, 24)
                                .background(.ultraThinMaterial)
                                .cornerRadius(28)
                                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                                .frame(maxWidth: 360)
                        }
                        .allowsHitTesting(false)
                        .transition(.opacity.combined(with: .scale))
                    } else if showRecordingPreview, let audioRecordingURL {
                        ZStack {
                            Color.black.opacity(0.8)
                                .ignoresSafeArea()
                                .transition(.opacity)

                            RecordingPreviewView(
                                audioURL: audioRecordingURL,
                                duration: recordingDuration,
                                isSending: isSendingVoice,
                                onSend: {
                                    sendVoiceMessage(audioURL: audioRecordingURL, duration: recordingDuration)
                                },
                                onDiscard: {
                                    discardRecording()
                                }
                            )
                            .padding(.vertical, 20)
                            .padding(.horizontal, 24)
                            .background(.ultraThinMaterial)
                            .cornerRadius(28)
                            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                            .frame(maxWidth: 360)
                        }
                        .transition(.opacity.combined(with: .scale))
                    }
                }
            }
        }
    }

    private func updateConversationOpenStateInFirestore(userId: String, isOpen: Bool) async {
        guard FirebaseAuthService.shared.auth.currentUser?.uid != nil else { return }
        do {
            let state: [String: Any] = [
                "openConversationUserId": isOpen ? userId : NSNull(),
                "updatedAt": Date().timeIntervalSince1970
            ]
            try await FirebaseAuthService.shared.updateUserData(state)
        } catch {}
    }

    private var messageComposer: some View {
        HStack(alignment: .center, spacing: 10) {
            TextField(t(.messagesTypeSomething), text: $replyText)
                .focused($isTextFieldFocused)
                .disabled(isSendingReply)
                .submitLabel(.send)
                .onSubmit { sendReply() }
                .textInputAutocapitalization(.sentences)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )

            Button {
                sendReply()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.white, Color.appGreen)
            }
            .buttonStyle(.plain)
            .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingReply)
            .opacity(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            .accessibilityLabel(t(.messagesSend))

            Button {
                showingImagePicker = true
            } label: {
                Image(systemName: "camera")
                    .font(.system(size: 20))
                    .foregroundColor(Color.appGreen)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isSendingReply)

            Circle()
                .fill(Color(.systemGray6))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 20))
                        .foregroundColor(isRecording ? .red : Color.appGreen)
                )
                .overlay(
                    Circle()
                        .stroke(isRecording ? Color.red.opacity(0.4) : Color.clear, lineWidth: 2)
                )
                .onLongPressGesture(minimumDuration: 0.2, maximumDistance: 60, pressing: { pressing in
                    if pressing {
                        if !isRecording { startRecording() }
                    } else if isRecording {
                        stopRecording()
                    }
                }, perform: {})
        }
    }

    private func modalFormattedDuration(_ time: TimeInterval) -> String {
        let total = max(Int(time.rounded()), 0)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func loadConversationMessages() {
        let otherUserId = message.senderName == MessageSenderLabel.currentUser ? message.recipientId : message.senderId

        if let cachedMessages = appState.getCachedConversationMessages(for: otherUserId) {
            Task {
                if !hasMarkedAsRead && message.senderName != MessageSenderLabel.currentUser {
                    try? await FirebaseAuthService.shared.markMessagesAsRead(from: otherUserId)
                    await MainActor.run { hasMarkedAsRead = true }
                }

                await MainActor.run {
                    conversationMessages = cachedMessages.sorted { $0.createdAt < $1.createdAt }
                    isLoadingMessages = false
                    previousMessageCount = conversationMessages.count
                }

                if currentUserProfilePhotoURL == nil || otherUserProfilePhotoURL == nil {
                    Task {
                        await fetchProfilePhotosIfNeeded(otherUserId: otherUserId)
                    }
                }

                await refreshConversationMessagesInBackground(otherUserId: otherUserId)
            }
            return
        }

        Task {
            do {
                if !hasMarkedAsRead && message.senderName != MessageSenderLabel.currentUser {
                    try await FirebaseAuthService.shared.markMessagesAsRead(from: otherUserId)
                    await MainActor.run { hasMarkedAsRead = true }
                }

                if otherUserResolvedName.isEmpty {
                    let name = (try? await FirebaseAuthService.shared.fetchDisplayName(for: otherUserId)) ?? ""
                    await MainActor.run { otherUserResolvedName = name }
                }

                await fetchProfilePhotosIfNeeded(otherUserId: otherUserId)

                let messages = try await FirebaseAuthService.shared.fetchConversationMessages(with: otherUserId)
                let displays = try await mapToDisplays(messages: messages, otherUserId: otherUserId)

                await MainActor.run {
                    conversationMessages = displays.sorted { $0.createdAt < $1.createdAt }
                    appState.cacheConversationMessages(conversationMessages, for: otherUserId)
                    isLoadingMessages = false
                    previousMessageCount = conversationMessages.count
                }
            } catch {
                await MainActor.run {
                    conversationMessages = [message].sorted { $0.createdAt < $1.createdAt }
                    isLoadingMessages = false
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if isLoadingMessages {
                conversationMessages = [message].sorted { $0.createdAt < $1.createdAt }
                isLoadingMessages = false
            }
        }
    }

    private func mapToDisplays(messages: [Message], otherUserId: String) async throws -> [MessageDisplay] {
        guard let myUid = FirebaseAuthService.shared.auth.currentUser?.uid else { return [] }
        let otherName: String
        if !otherUserResolvedName.isEmpty {
            otherName = otherUserResolvedName
        } else {
            otherName = try await FirebaseAuthService.shared.fetchDisplayName(for: otherUserId)
        }

        return messages.sorted { $0.createdAt < $1.createdAt }.map { m in
            let isMe = m.senderFirebaseId == myUid
            return MessageDisplay(
                message: m,
                senderName: isMe ? MessageSenderLabel.currentUser : otherName,
                recipientName: isMe ? otherName : MessageSenderLabel.currentUser,
                senderId: m.senderFirebaseId,
                recipientId: isMe ? otherUserId : myUid,
                senderProfilePhotoURL: isMe ? currentUserProfilePhotoURL : otherUserProfilePhotoURL,
                recipientProfilePhotoURL: isMe ? otherUserProfilePhotoURL : currentUserProfilePhotoURL
            )
        }
    }

    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            refreshMessagesOnly()
        }
    }

    private func refreshMessagesOnly() {
        let otherUserId = message.senderName == MessageSenderLabel.currentUser ? message.recipientId : message.senderId
        Task {
            await refreshConversationMessagesInBackground(otherUserId: otherUserId)
        }
    }

    private func refreshConversationMessagesInBackground(otherUserId: String) async {
        do {
            let messageContent = try await FirebaseAuthService.shared.fetchConversationMessagesContentOnly(with: otherUserId)
            let oldCount = await MainActor.run { conversationMessages.count }

            await fetchProfilePhotosIfNeeded(otherUserId: otherUserId)
            let displays = try await mapToDisplays(messages: messageContent, otherUserId: otherUserId)

            await MainActor.run {
                conversationMessages = displays.sorted { $0.createdAt < $1.createdAt }
                appState.updateConversationMessagesCache(conversationMessages, for: otherUserId)

                let newCount = conversationMessages.count
                if newCount > oldCount {
                    let currentUserId = FirebaseAuthService.shared.auth.currentUser?.uid ?? ""
                    let hasNewIncoming = conversationMessages.suffix(newCount - oldCount).contains { msg in
                        msg.senderId != currentUserId
                    }
                    if hasNewIncoming {
                        SoundService.shared.playNewMessageSound()
                    }
                }
                previousMessageCount = newCount
            }
        } catch {}
    }

    private func fetchProfilePhotosIfNeeded(otherUserId: String) async {
        guard let currentUserId = FirebaseAuthService.shared.auth.currentUser?.uid else { return }
        do {
            async let currentUserPhoto = FirebaseAuthService.shared.fetchUserProfilePhotoURL(for: currentUserId)
            async let otherUserPhoto = FirebaseAuthService.shared.fetchUserProfilePhotoURL(for: otherUserId)
            let (currentPhoto, otherPhoto) = try await (currentUserPhoto, otherUserPhoto)
            await MainActor.run {
                currentUserProfilePhotoURL = currentPhoto
                otherUserProfilePhotoURL = otherPhoto
            }
        } catch {}
    }

    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func sendReply() {
        let trimmed = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSendingReply = true
        let recipientId = message.senderName == MessageSenderLabel.currentUser ? message.recipientId : message.senderId

        Task {
            do {
                await fetchProfilePhotosIfNeeded(otherUserId: recipientId)
                _ = try await FirebaseAuthService.shared.sendMessage(to: recipientId, content: trimmed)
                await MainActor.run {
                    updateConversationListAfterOutgoingMessage(content: trimmed, type: .text, voiceDuration: nil)
                    replyText = ""
                    isSendingReply = false
                    refreshMessagesOnly()
                }
            } catch {
                await MainActor.run {
                    isSendingReply = false
                }
            }
        }
    }

    private func sendImageMessage(image: UIImage) {
        guard let currentUserId = FirebaseAuthService.shared.auth.currentUser?.uid else { return }

        Task {
            do {
                let recipientId = message.senderName == MessageSenderLabel.currentUser ? message.recipientId : message.senderId
                await fetchProfilePhotosIfNeeded(otherUserId: recipientId)
                let imageURL = try await PhotoStorageService.shared.uploadMessageImage(image, for: currentUserId)
                _ = try await FirebaseAuthService.shared.sendImageMessage(to: recipientId, imageURL: imageURL)

                await MainActor.run {
                    selectedImage = nil
                    updateConversationListAfterOutgoingMessage(content: imageURL, type: .image, voiceDuration: nil)
                    refreshMessagesOnly()
                }
            } catch {
                await MainActor.run {
                    selectedImage = nil
                }
            }
        }
    }

    private func startRecording() {
        if showRecordingPreview {
            discardRecording()
        }
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    beginRecordingSession()
                } else {
                    showingMicrophonePermissionAlert = true
                }
            }
        }
    }

    private func beginRecordingSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)

            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("voice_\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()

            audioRecordingURL = fileURL
            recordingDuration = 0
            recordingTimer?.invalidate()
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                recordingDuration = audioRecorder?.currentTime ?? recordingDuration
            }

            withAnimation {
                isRecording = true
            }
        } catch {
            showingMicrophonePermissionAlert = true
            discardRecording()
        }
    }

    private func stopRecording() {
        guard isRecording else { return }

        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil

        let capturedDuration = audioRecorder?.currentTime ?? recordingDuration
        audioRecorder = nil

        withAnimation {
            isRecording = false
        }

        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])

        recordingDuration = max(capturedDuration, 0.1)
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85, blendDuration: 0.2)) {
                showRecordingPreview = true
            }
        }
    }

    private func discardRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioRecorder?.stop()
        audioRecorder = nil

        if let url = audioRecordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        audioRecordingURL = nil
        recordingDuration = 0

        withAnimation {
            showRecordingPreview = false
        }
    }

    private func sendVoiceMessage(audioURL: URL, duration: TimeInterval) {
        guard !isSendingVoice else { return }
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            discardRecording()
            return
        }
        guard let currentUserId = FirebaseAuthService.shared.auth.currentUser?.uid else {
            discardRecording()
            return
        }

        isSendingVoice = true

        Task {
            do {
                let recipientId = message.senderName == MessageSenderLabel.currentUser ? message.recipientId : message.senderId
                let remoteURL = try await PhotoStorageService.shared.uploadVoiceMessage(audioURL, for: currentUserId)
                _ = try await FirebaseAuthService.shared.sendVoiceMessage(to: recipientId, audioURL: remoteURL, duration: duration)

                try? FileManager.default.removeItem(at: audioURL)

                await MainActor.run {
                    isSendingVoice = false
                    discardRecording()
                    refreshMessagesOnly()
                }
            } catch {
                await MainActor.run {
                    isSendingVoice = false
                }
            }
        }
    }

    private func updateConversationListAfterOutgoingMessage(content: String, type: MessageType, voiceDuration: TimeInterval?) {
        guard let currentUserId = FirebaseAuthService.shared.auth.currentUser?.uid else { return }
        let otherUserId = message.senderName == MessageSenderLabel.currentUser ? message.recipientId : message.senderId
        let otherUserName = message.senderName == MessageSenderLabel.currentUser ? message.recipientName : message.senderName
        let newMessage = Message(
            id: UUID().uuidString,
            conversationId: UUID(),
            senderId: UUID(),
            senderFirebaseId: currentUserId,
            content: content,
            type: type,
            createdAt: Date(),
            voiceDuration: voiceDuration
        )
        let messageDisplay = MessageDisplay(
            message: newMessage,
            senderName: MessageSenderLabel.currentUser,
            recipientName: otherUserName,
            senderId: currentUserId,
            recipientId: otherUserId,
            senderProfilePhotoURL: currentUserProfilePhotoURL,
            recipientProfilePhotoURL: otherUserProfilePhotoURL
        )
        // Must update the thread binding — inbox cache alone does not refresh the modal’s `conversationMessages`.
        var merged = conversationMessages
        merged.append(messageDisplay)
        conversationMessages = merged.sorted { $0.createdAt < $1.createdAt }
        appState.updateConversationMessagesCache(conversationMessages, for: otherUserId)
        appState.updateConversationInCache(messageDisplay)
    }
}
