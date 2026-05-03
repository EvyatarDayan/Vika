//
//  MessageThreadComponents.swift
//  Vika
//

import AVFoundation
import Photos
import PhotosUI
import SwiftUI
import UIKit

// MARK: - Message bubble

struct MessageBubble: View {
    let message: MessageDisplay
    let currentUserProfilePhotoURL: String?
    let otherUserProfilePhotoURL: String?
    let conversationMessages: [MessageDisplay]
    @Binding var showingConversationPhotoViewer: Bool
    @Binding var selectedPhotoIndex: Int
    @Environment(\.messagesLanguageCode) private var languageCode

    private func t(_ key: VikaL10n.Key) -> String {
        VikaL10n.t(key, languageCode: languageCode)
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                if message.senderName == MessageSenderLabel.currentUser {
                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        bubbleContent(isFromCurrentUser: true)
                    }

                    currentUserAvatar
                } else {
                    otherUserAvatar

                    VStack(alignment: .leading, spacing: 4) {
                        bubbleContent(isFromCurrentUser: false)
                    }
                    Spacer()
                }
            }

            HStack {
                if message.senderName == MessageSenderLabel.currentUser {
                    Spacer()
                    Text(message.createdAt.messagesFormattedTimestamp(languageCode: languageCode))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 40)
                } else {
                    Text(message.createdAt.messagesFormattedTimestamp(languageCode: languageCode))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 40)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func bubbleContent(isFromCurrentUser: Bool) -> some View {
        switch message.messageType {
        case .image:
            Button {
                let imageMessages = conversationMessages.filter { $0.messageType == .image }
                if let index = imageMessages.firstIndex(where: { $0.id == message.id }) {
                    selectedPhotoIndex = index
                    showingConversationPhotoViewer = true
                }
            } label: {
                AsyncImage(url: URL(string: message.content)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 150, maxHeight: 150)
                            .cornerRadius(10)
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .frame(width: 150, height: 150)
                    case .empty:
                        ProgressView()
                            .frame(width: 150, height: 150)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .buttonStyle(.plain)

        case .voice:
            VoiceMessagePlayerView(
                audioURL: URL(string: message.content),
                displayDuration: message.voiceDuration,
                accentColor: .white,
                textColor: .white,
                baseColor: Color.appGreen,
                waveColor: .white
            )

        default:
            Text(message.content)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
                .padding(8)
                .background(isFromCurrentUser ? Color.appGreen.opacity(0.22) : Color.green.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(10)
        }
    }

    @ViewBuilder
    private var currentUserAvatar: some View {
        avatarCircle(
            url: currentUserProfilePhotoURL,
            placeholder: String(t(.messagesYou).prefix(1)).uppercased()
        )
    }

    @ViewBuilder
    private var otherUserAvatar: some View {
        avatarCircle(
            url: otherUserProfilePhotoURL,
            placeholder: String(message.senderName.prefix(1)).uppercased()
        )
    }

    private func avatarCircle(url: String?, placeholder: String) -> some View {
        Group {
            if let profilePhotoURL = url, !profilePhotoURL.isEmpty {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay(
                        CachedAsyncImage(url: URL(string: profilePhotoURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.appGreen.opacity(0.2))
                                .overlay(
                                    Text(placeholder)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.appGreen)
                                )
                        }
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                    )
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .fill(Color.appGreen.opacity(0.2))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text(placeholder)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.appGreen)
                            )
                    )
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
            }
        }
    }
}

// MARK: - Image picker

struct MessageImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MessageImagePicker

        init(_ parent: MessageImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            guard let result = results.first else { return }
            result.itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                if let image = image as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image
                    }
                }
            }
        }
    }
}

// MARK: - Recording UI

struct RecordingIndicatorView: View {
    let durationText: String
    @State private var animate = false
    @Environment(\.messagesLanguageCode) private var languageCode

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(VikaL10n.t(.messagesVoiceRecording, languageCode: languageCode))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .scaleEffect(animate ? 1.2 : 0.9)
                    .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: animate)
                    .onAppear { animate = true }
                Text(durationText)
                    .font(.title3)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct RecordingPreviewView: View {
    let audioURL: URL
    let duration: TimeInterval
    let isSending: Bool
    let onSend: () -> Void
    let onDiscard: () -> Void
    @Environment(\.messagesLanguageCode) private var languageCode

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(VikaL10n.t(.messagesVoiceReady, languageCode: languageCode))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer()
            }

            VoiceMessagePlayerView(
                audioURL: audioURL,
                displayDuration: duration,
                accentColor: .white,
                textColor: .white,
                baseColor: .gray,
                waveColor: .white
            )

            HStack {
                Button(role: .destructive, action: onDiscard) {
                    Label(VikaL10n.t(.commonDelete, languageCode: languageCode), systemImage: "trash")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Spacer()

                Button(action: onSend) {
                    if isSending {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Label(VikaL10n.t(.messagesSend, languageCode: languageCode), systemImage: "paperplane.fill")
                            .font(.subheadline)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.appGreen)
                .disabled(isSending)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
    }
}

// MARK: - Voice player

struct VoiceMessagePlayerView: View {
    let audioURL: URL?
    let displayDuration: TimeInterval?
    let accentColor: Color
    let textColor: Color
    let baseColor: Color
    let waveColor: Color

    @State private var audioPlayer: AVAudioPlayer?
    @State private var isLoading = false
    @State private var isPlaying = false
    @State private var loadError = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var playbackTimer: Timer?
    @State private var tempFileURL: URL?
    @State private var pendingAutoPlay = false
    @State private var showElapsedTime = false

    var body: some View {
        let bubbleHeight: CGFloat = 80
        ZStack(alignment: .bottomTrailing) {
            VoiceMessageBackground(baseColor: baseColor, waveColor: waveColor, progress: progress)
                .frame(height: bubbleHeight)

            HStack(spacing: 12) {
                Button(action: togglePlayback) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.18))
                            .frame(width: 44, height: 44)
                        if isLoading {
                            ProgressView()
                                .tint(accentColor)
                        } else if loadError {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                        } else {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .foregroundColor(accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isLoading || loadError || audioURL == nil)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: bubbleHeight, alignment: .center)

            Text(displayTime)
                .font(.caption)
                .foregroundColor(textColor.opacity(0.75))
                .padding(.trailing, 16)
                .padding(.bottom, 10)
        }
        .onAppear {
            if duration == 0, let displayDuration {
                duration = displayDuration
            }
            prepareAudioIfNeeded(autoPlay: false)
        }
        .onDisappear {
            stopPlayback(resetPosition: true)
            if let tempFileURL {
                try? FileManager.default.removeItem(at: tempFileURL)
            }
            audioPlayer = nil
        }
    }

    private var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0), 1)
    }

    private var displayTime: String {
        if showElapsedTime {
            return threadFormattedDuration(currentTime)
        }
        return threadFormattedDuration(duration > 0 ? duration : (displayDuration ?? 0))
    }

    private func togglePlayback() {
        if isPlaying {
            stopPlayback(resetPosition: false)
        } else if audioPlayer == nil {
            prepareAudioIfNeeded(autoPlay: true)
        } else {
            startPlayback()
        }
    }

    private func prepareAudioIfNeeded(autoPlay: Bool) {
        guard audioPlayer == nil, !isLoading else {
            if autoPlay { startPlayback() }
            return
        }
        guard let audioURL else {
            loadError = true
            return
        }

        isLoading = true
        loadError = false
        pendingAutoPlay = autoPlay

        Task {
            do {
                let localURL: URL
                if audioURL.isFileURL {
                    localURL = audioURL
                } else {
                    let (data, _) = try await URLSession.shared.data(from: audioURL)
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("voice_preview_\(UUID().uuidString).m4a")
                    try data.write(to: tempURL, options: .atomic)
                    localURL = tempURL
                    await MainActor.run { tempFileURL = tempURL }
                }

                let player = try AVAudioPlayer(contentsOf: localURL)
                player.prepareToPlay()
                let actualDuration = player.duration

                await MainActor.run {
                    audioPlayer = player
                    if actualDuration > 0 {
                        duration = actualDuration
                    } else if let displayDuration, displayDuration > 0 {
                        duration = displayDuration
                    }
                    isLoading = false

                    if pendingAutoPlay {
                        startPlayback()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    loadError = true
                    showElapsedTime = false
                }
            }
        }
    }

    private func startPlayback() {
        guard let player = audioPlayer else { return }
        player.currentTime = currentTime
        if player.duration > 0 {
            duration = player.duration
        }
        player.play()
        isPlaying = true
        showElapsedTime = true
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            currentTime = min(player.currentTime, duration)
            if !player.isPlaying {
                stopPlayback(resetPosition: true)
            }
        }
    }

    private func stopPlayback(resetPosition: Bool) {
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
        if resetPosition {
            currentTime = 0
            showElapsedTime = false
        }
    }
}

struct VoiceMessageBackground: View {
    let baseColor: Color
    let waveColor: Color
    let progress: Double
    private let cornerRadius: CGFloat = 16
    private let barCount = 32
    private let leadingInset: CGFloat = 90
    private let trailingInset: CGFloat = 24

    var body: some View {
        GeometryReader { proxy in
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            ZStack {
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                baseColor.opacity(0.95),
                                baseColor.opacity(0.82)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Canvas { context, size in
                    let waveWidth = max(0, size.width - leadingInset - trailingInset)
                    guard waveWidth > 0 else { return }
                    let step = waveWidth / CGFloat(max(barCount - 1, 1))
                    let centerY = size.height / 2
                    for index in 0..<barCount {
                        let currentWidth = barWidth(for: index)
                        let currentHeight = barHeight(for: index)
                        let xPosition = leadingInset + step * CGFloat(index)
                        let rect = CGRect(
                            x: xPosition - currentWidth / 2,
                            y: centerY - currentHeight / 2,
                            width: currentWidth,
                            height: currentHeight
                        )
                        let path = Path(roundedRect: rect, cornerRadius: currentWidth / 2)
                        context.fill(path, with: .color(barColor(for: index)))
                    }
                }
                .clipShape(shape)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let pattern: [CGFloat] = [20, 14, 24, 12, 26, 15, 22, 13, 24, 16, 20, 14, 28, 17, 22, 15, 24, 14, 22, 15, 24, 13]
        return pattern[index % pattern.count]
    }

    private func barWidth(for index: Int) -> CGFloat {
        index % 3 == 0 ? 3 : 2
    }

    private func barColor(for index: Int) -> Color {
        let normalized = Double(index) / Double(max(barCount - 1, 1))
        let highlightWidth = 0.22
        let distance = progress - normalized
        let emphasis = max(0.0, min(1.0, (distance + highlightWidth) / highlightWidth))
        let baseRGB: (Double, Double, Double) = (0.70, 0.72, 0.75)
        let targetRGB: (Double, Double, Double) = (1.0, 1.0, 1.0)
        let red = baseRGB.0 + (targetRGB.0 - baseRGB.0) * emphasis
        let green = baseRGB.1 + (targetRGB.1 - baseRGB.1) * emphasis
        let blue = baseRGB.2 + (targetRGB.2 - baseRGB.2) * emphasis
        let opacity = 0.55 + (0.4 * emphasis)
        return Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

private func threadFormattedDuration(_ interval: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.zeroFormattingBehavior = .pad
    formatter.allowedUnits = interval >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
    return formatter.string(from: interval) ?? "0:00"
}

// MARK: - Photo viewer

struct ConversationPhotoViewerModal: View {
    let photos: [String]
    @Binding var selectedIndex: Int
    let conversationMessages: [MessageDisplay]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.messagesLanguageCode) private var languageCode

    @State private var showingSaveAlert = false
    @State private var saveSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                if !photos.isEmpty {
                    TabView(selection: $selectedIndex) {
                        ForEach(Array(photos.enumerated()), id: \.offset) { index, photoURL in
                            CachedAsyncImage(url: URL(string: photoURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .tint(.white)
                                    }
                            }
                            .padding(.horizontal, 40)
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    .onAppear {
                        preloadAllPhotos()
                    }
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.white)

                        Text(VikaL10n.t(.profileNoPhotos, languageCode: languageCode))
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(VikaL10n.t(.settingsDone, languageCode: languageCode)) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(VikaL10n.t(.commonSave, languageCode: languageCode)) {
                        guard selectedIndex >= 0, selectedIndex < photos.count else { return }
                        saveImageToPhotoLibrary(imageURL: photos[selectedIndex])
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert(VikaL10n.t(.messagesImageSaved, languageCode: languageCode), isPresented: $showingSaveAlert) {
                Button(VikaL10n.t(.alertOK, languageCode: languageCode), role: .cancel) {}
            } message: {
                Text(saveSuccess ? VikaL10n.t(.messagesImageSavedSuccess, languageCode: languageCode) : VikaL10n.t(.messagesImageSavedFailed, languageCode: languageCode))
            }
        }
    }

    private func saveImageToPhotoLibrary(imageURL: String) {
        guard let url = URL(string: imageURL) else {
            saveSuccess = false
            showingSaveAlert = true
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else {
                    await MainActor.run {
                        saveSuccess = false
                        showingSaveAlert = true
                    }
                    return
                }

                let currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
                let status: PHAuthorizationStatus
                if currentStatus == .notDetermined {
                    status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                } else {
                    status = currentStatus
                }

                guard status == .authorized || status == .limited else {
                    await MainActor.run {
                        saveSuccess = false
                        showingSaveAlert = true
                    }
                    return
                }

                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }, completionHandler: { success, _ in
                    DispatchQueue.main.async {
                        saveSuccess = success
                        showingSaveAlert = true
                    }
                })
            } catch {
                await MainActor.run {
                    saveSuccess = false
                    showingSaveAlert = true
                }
            }
        }
    }

    private func preloadAllPhotos() {
        Task {
            await withTaskGroup(of: Void.self) { group in
                for photoURL in photos {
                    group.addTask {
                        guard let url = URL(string: photoURL) else { return }
                        let alreadyCached = await MainActor.run {
                            ImageCacheService.shared.image(for: photoURL) != nil
                        }
                        if alreadyCached { return }
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            if let uiImage = UIImage(data: data) {
                                await MainActor.run {
                                    ImageCacheService.shared.insert(uiImage, for: photoURL)
                                }
                            }
                        } catch {}
                    }
                }
            }
        }
    }
}
