//
//  LivePayView.swift
//  Vika
//

import SwiftUI
import Combine
import FirebaseDatabase

@MainActor
private final class LivePayFavoriteFoldersModel: ObservableObject {
    @Published private(set) var folders: [UserProfile] = []
    @Published private(set) var isLoading = true

    private var usersRef: DatabaseReference?
    private var favRef: DatabaseReference?
    private var usersHandle: DatabaseHandle?
    private var favHandle: DatabaseHandle?
    private var allById: [String: UserProfile] = [:]
    private var favoriteIds: Set<String> = []
    private var currentUserId = ""

    func start(currentUserId: String) {
        stop()
        self.currentUserId = currentUserId
        isLoading = true

        let root = Database.database().reference().child("users")
        usersRef = root

        usersHandle = root.observe(.value) { [weak self] snapshot in
            guard let self else { return }
            Task { @MainActor in
                self.mergeUsers(snapshot)
                self.rebuildFolders()
                self.isLoading = false
            }
        }

        favRef = root.child(currentUserId).child("favoriteFolderIds")
        favHandle = favRef?.observe(.value) { [weak self] snapshot in
            guard let self else { return }
            Task { @MainActor in
                self.favoriteIds = Self.parseFavoriteIds(snapshot)
                self.rebuildFolders()
            }
        }
    }

    func stop() {
        if let usersRef, let usersHandle {
            usersRef.removeObserver(withHandle: usersHandle)
        }
        if let favRef, let favHandle {
            favRef.removeObserver(withHandle: favHandle)
        }
        usersRef = nil
        favRef = nil
        usersHandle = nil
        favHandle = nil
    }

    private func mergeUsers(_ snapshot: DataSnapshot) {
        guard let value = snapshot.value as? [String: [String: Any]] else {
            allById = [:]
            return
        }
        var next: [String: UserProfile] = [:]
        for (uid, payload) in value {
            guard uid != currentUserId, let p = UserProfile(id: uid, dictionary: payload) else { continue }
            next[uid] = p
        }
        allById = next
    }

    private func rebuildFolders() {
        folders = favoriteIds.compactMap { allById[$0] }
            .filter { $0.role == .folder || $0.isFolder }
            .sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
    }

    private static func parseFavoriteIds(_ snapshot: DataSnapshot) -> Set<String> {
        guard snapshot.exists(), let value = snapshot.value as? [String: Any] else { return [] }
        var result: Set<String> = []
        for (key, val) in value {
            if let b = val as? Bool, b {
                result.insert(key)
            } else if let n = val as? NSNumber, n.boolValue {
                result.insert(key)
            }
        }
        return result
    }
}

struct LivePayView: View {
    let currentUser: UserProfile
    @Binding var selectedTab: Int
    @ObservedObject var historyStore: LivePaymentHistoryStore

    @AppStorage("selectedLanguage") private var selectedLanguageCode = "en"
    @AppStorage(LocaleCurrency.appStorageKey) private var storedCurrencyCode = ""

    @StateObject private var favoriteFoldersModel = LivePayFavoriteFoldersModel()

    @State private var hourlyRate = ""
    @State private var folderName = ""
    @State private var otherPays = ""

    @State private var isLivePayRunning = false
    @State private var livePayStartTime: Date?
    @State private var livePayEndTime: Date?
    @State private var currentTime = Date()

    @State private var previousProgress: Double = 0
    @State private var isResetting = false
    @State private var resetProgress: Double = 1

    @State private var playPulse = false
    @State private var selectPulse = false

    @State private var showFavoriteFoldersSheet = false
    @State private var showStopConfirmation = false

    private func t(_ key: VikaL10n.Key) -> String {
        VikaL10n.t(key, languageCode: selectedLanguageCode)
    }

    private var currencySymbol: String {
        let code = LocaleCurrency.resolvedCode(storedOverride: storedCurrencyCode)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = Locale(identifier: "en_US")
        return formatter.currencySymbol ?? code
    }

    private var livePayDuration: TimeInterval {
        guard let start = livePayStartTime else { return 0 }
        let end = isLivePayRunning ? currentTime : (livePayEndTime ?? currentTime)
        return max(0, end.timeIntervalSince(start))
    }

    private var livePayDurationHours: Double {
        livePayDuration / 3600
    }

    private var livePayAmount: Double {
        let rate = Double(hourlyRate) ?? 0
        let base = max(0, rate * livePayDurationHours)
        let other = Double(otherPays) ?? 0
        return base + other
    }

    private var formattedDuration: String {
        let hours = Int(livePayDurationHours)
        let minutes = Int((livePayDurationHours - Double(hours)) * 60)
        let seconds = Int(livePayDuration.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var progressValue: Double {
        guard isLivePayRunning else { return 0 }
        let secondsInCycle = livePayDuration.truncatingRemainder(dividingBy: 120)
        return secondsInCycle / 120
    }

    private var canStartLivePay: Bool {
        !hourlyRate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && Double(hourlyRate) != nil
    }

    private var folderPayInfoText: String? {
        guard !folderName.isEmpty else { return nil }
        let first = folderName.split(separator: " ").first.map(String.init) ?? folderName
        let hr = Double(hourlyRate) ?? 0
        let other = Double(otherPays) ?? 0
        if hr > 0, other > 0 {
            return "\(first) · \(currencySymbol)\(String(format: "%.2f", hr)) + \(currencySymbol)\(String(format: "%.2f", other))"
        }
        if hr > 0 {
            return "\(first) · \(currencySymbol)\(String(format: "%.2f", hr))/h"
        }
        return nil
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Color.clear.frame(height: 20)

                    ZStack {
                        Circle()
                            .stroke(Color.appGreen.opacity(0.2), lineWidth: 20)
                            .frame(width: 250, height: 250)

                        if isResetting {
                            Circle()
                                .trim(from: 0, to: resetProgress)
                                .stroke(Color.appGreen, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                                .frame(width: 250, height: 250)
                                .rotationEffect(.degrees(-90))
                                .opacity(resetProgress > 0 ? 1 : 0)
                                .animation(.easeOut(duration: 0.8), value: resetProgress)
                        }

                        Circle()
                            .trim(from: 0, to: progressValue)
                            .stroke(Color.appGreen, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .frame(width: 250, height: 250)
                            .rotationEffect(.degrees(-90))
                            .opacity(isResetting ? 0 : 1)
                            .animation(.linear(duration: 0.1), value: progressValue)
                            .onChange(of: progressValue) { _, newValue in
                                checkForReset(newValue: newValue)
                            }

                        VStack(spacing: 8) {
                            if isLivePayRunning {
                                Text(formattedDuration)
                                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.primary)
                                Text(t(.livePaySessionRunning))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else if livePayStartTime != nil {
                                Text(formattedDuration)
                                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.primary)
                                Text(t(.livePaySessionEnded))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("0:00")
                                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                Text(t(.livePayReadyToStart))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(height: geometry.size.height * 0.4)
                    .padding(.bottom, 45)

                    HStack(alignment: .top, spacing: 0) {
                        VStack(spacing: 4) {
                            Image("Duration")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.secondary)
                            Text(t(.livePayDuration))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text((isLivePayRunning || livePayStartTime != nil) ? formattedDuration : "0:00")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.appGreen)
                        }
                        .frame(maxWidth: .infinity)

                        Button {
                            if isLivePayRunning {
                                showStopConfirmation = true
                            } else if canStartLivePay {
                                toggleLivePay()
                            } else {
                                showFavoriteFoldersSheet = true
                            }
                        } label: {
                            if isLivePayRunning {
                                Image("stop")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundStyle(Color(white: 0.35))
                            } else {
                                Image("start")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundStyle(canStartLivePay ? Color.appGreen : Color(white: 0.35))
                                    .scaleEffect(playPulse ? 1.08 : 1.0)
                                    .animation(
                                        canStartLivePay && !isLivePayRunning
                                            ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true)
                                            : .default,
                                        value: playPulse
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 80)
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 4) {
                            Image("Pay")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.secondary)
                            Text(t(.livePayPay))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 2) {
                                Text(currencySymbol)
                                    .font(.system(size: 22, weight: .bold))
                                Text(
                                    (isLivePayRunning || livePayStartTime != nil)
                                        ? String(format: "%.2f", livePayAmount)
                                        : "0.00"
                                )
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                            }
                            .foregroundStyle(Color.appGreen)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)

                    VStack(spacing: 4) {
                        if !folderName.isEmpty {
                            Button {
                                if !isLivePayRunning {
                                    showFavoriteFoldersSheet = true
                                }
                            } label: {
                                Text(folderName)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.center)
                            }
                            .buttonStyle(.plain)
                            .disabled(isLivePayRunning)
                            .padding(.bottom, 8)

                            if let info = folderPayInfoText {
                                Text(info)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        } else {
                            Button {
                                showFavoriteFoldersSheet = true
                            } label: {
                                Text(t(.livePaySelectFolderToStart))
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(selectPulse ? Color.appGreen : Color.secondary)
                                    .multilineTextAlignment(.center)
                                    .scaleEffect(selectPulse ? 1.06 : 1.0)
                                    .animation(
                                        !canStartLivePay && !isLivePayRunning
                                            ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true)
                                            : .default,
                                        value: selectPulse
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 120)
                    .padding(.top, 12)
                    .padding(.horizontal, 32)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(t(.livePayTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFavoriteFoldersSheet = true
                } label: {
                    Image(systemName: "basket.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            isLivePayRunning ? Color.appGreen.opacity(0.4) : Color.appGreen,
                            in: Circle()
                        )
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                }
                .disabled(isLivePayRunning)
                .buttonStyle(.plain)
                .accessibilityLabel(t(.livePayFolderToolbar))
            }
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            if isLivePayRunning {
                currentTime = Date()
            }
        }
        .onAppear {
            favoriteFoldersModel.start(currentUserId: currentUser.id)
            playPulse = true
            selectPulse = true
        }
        .onDisappear {
            favoriteFoldersModel.stop()
        }
        .sheet(isPresented: $showFavoriteFoldersSheet) {
            FavoriteFoldersSheet(
                model: favoriteFoldersModel,
                onPick: { profile in
                    folderName = profile.fullName
                    if profile.chargingFee > 0 {
                        hourlyRate = String(format: "%.2f", profile.chargingFee)
                    }
                    showFavoriteFoldersSheet = false
                },
                onFindOtherFolders: {
                    showFavoriteFoldersSheet = false
                    selectedTab = 2
                },
                title: t(.livePayFavoriteFoldersTitle),
                emptyMessage: t(.livePayNoFavoriteFolders),
                languageCode: selectedLanguageCode
            )
        }
        .alert(t(.livePayStopConfirmTitle), isPresented: $showStopConfirmation) {
            Button(t(.livePayContinue), role: .cancel) {}
            Button(t(.livePayYesStop), role: .destructive) {
                toggleLivePayStopping()
            }
        } message: {
            Text(t(.livePayStopConfirmMessage))
        }
    }

    private func checkForReset(newValue: Double) {
        let current = newValue
        if previousProgress > 0.9 && current < 0.1 {
            isResetting = true
            resetProgress = 1
            withAnimation(.easeOut(duration: 2.8)) {
                resetProgress = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isResetting = false
                resetProgress = 1
            }
        }
        previousProgress = current
    }

    private func toggleLivePay() {
        livePayStartTime = Date()
        livePayEndTime = nil
        isLivePayRunning = true
        previousProgress = 0
        isResetting = false
    }

    private func toggleLivePayStopping() {
        guard let start = livePayStartTime else {
            livePayEndTime = Date()
            isLivePayRunning = false
            return
        }
        let end = Date()
        livePayEndTime = end
        isLivePayRunning = false

        let duration = max(0, end.timeIntervalSince(start))
        let hours = duration / 3600
        let rate = Double(hourlyRate) ?? 0
        let other = Double(otherPays) ?? 0
        let total = max(0, rate * hours) + other
        let code = LocaleCurrency.resolvedCode(storedOverride: storedCurrencyCode)
        let trimmedName = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        let record = LivePaymentRecord(
            folderName: trimmedName.isEmpty ? "—" : trimmedName,
            totalPay: total,
            duration: duration,
            date: end,
            currencyCode: code,
            startTime: start,
            endTime: end,
            hourlyRate: rate,
            otherPays: other,
            isPaid: false
        )
        historyStore.add(record)

        livePayStartTime = nil
        livePayEndTime = nil
    }
}

private struct FavoriteFoldersSheet: View {
    @ObservedObject var model: LivePayFavoriteFoldersModel
    let onPick: (UserProfile) -> Void
    let onFindOtherFolders: () -> Void
    let title: String
    let emptyMessage: String
    let languageCode: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if model.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if model.folders.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "star.slash")
                            .font(.system(size: 40))
                            .foregroundStyle(.tertiary)
                        Text(emptyMessage)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(model.folders) { profile in
                        Button {
                            onPick(profile)
                        } label: {
                            HStack(spacing: 12) {
                                folderThumb(profile)
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(profile.fullName)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(profile.email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(VikaL10n.t(.settingsDone, languageCode: languageCode)) {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button(action: onFindOtherFolders) {
                    Text(VikaL10n.t(.livePayFindOtherFolders, languageCode: languageCode))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.appGreen)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGroupedBackground))
            }
        }
    }

    @ViewBuilder
    private func folderThumb(_ profile: UserProfile) -> some View {
        if let urlString = profile.profileImageURL,
           let url = URL(string: urlString),
           !urlString.isEmpty {
            AsyncImage(url: url) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appGreen.opacity(0.2))
            }
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.appGreen.opacity(0.2))
                .overlay {
                    Image(systemName: "basket.fill")
                        .foregroundStyle(Color.appGreen)
                }
        }
    }
}

#Preview {
    NavigationStack {
        LivePayView(
            currentUser: UserProfile(
                id: "me",
                firstName: "Me",
                lastName: "Client",
                phoneNumber: "",
                email: "me@test.com",
                address: "",
                profileImageURL: nil,
                role: .client,
                createdAt: nil,
                updatedAt: nil,
                lastLoginAt: nil
            ),
            selectedTab: .constant(1),
            historyStore: LivePaymentHistoryStore(userId: "me")
        )
    }
}
