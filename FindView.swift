//
//  FindView.swift
//  Vika
//

import SwiftUI
import Combine
import FirebaseDatabase
import CoreLocation
import MapKit

private enum FindAudience: String, CaseIterable, Identifiable {
    case folders = "Folders"
    case clients = "Clients"

    var id: String { rawValue }

    var targetRole: UserRole {
        switch self {
        case .folders: return .folder
        case .clients: return .client
        }
    }
}

private enum FindListFilter: String, CaseIterable, Identifiable {
    case all
    case favorites
    case nearby

    var id: String { rawValue }
}

@MainActor
private final class FavoriteFolderIdsObserver: ObservableObject {
    @Published private(set) var ids: Set<String> = []

    private var ref: DatabaseReference?
    private var handle: DatabaseHandle?

    func start(currentUserId: String) {
        stop()
        let r = Database.database().reference()
            .child("users")
            .child(currentUserId)
            .child("favoriteFolderIds")
        ref = r
        handle = r.observe(.value) { [weak self] snapshot in
            Task { @MainActor in
                self?.ids = Self.parseFavoriteIds(snapshot)
            }
        }
    }

    func stop() {
        if let ref, let handle {
            ref.removeObserver(withHandle: handle)
        }
        ref = nil
        handle = nil
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

@MainActor
private final class FindViewModel: ObservableObject {
    @Published private var allProfiles: [UserProfile] = []
    @Published var searchText = ""
    @Published var selectedAudience: FindAudience = .folders
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var usersRef: DatabaseReference?
    private var handle: DatabaseHandle?
    private var currentUserID = ""

    var filteredProfiles: [UserProfile] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return allProfiles
                .filter { profile in
            // `role` was not persisted correctly for folder sign-ups in older builds; `isFolder` is the edit-profile source of truth.
            guard profile.role == .folder || profile.isFolder else { return false }
            guard !query.isEmpty else { return true }
            return profile.fullName.lowercased().contains(query) || profile.email.lowercased().contains(query)
        }
            .sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
    }

    func start(currentUser: UserProfile) {
        currentUserID = currentUser.id
        isLoading = true
        errorMessage = nil

        let ref = Database.database().reference().child("users")
        usersRef = ref

        handle = ref.observe(.value) { [weak self] snapshot in
            guard let self else { return }

            guard let value = snapshot.value as? [String: [String: Any]] else {
                self.allProfiles = []
                self.isLoading = false
                return
            }

            self.allProfiles = value.compactMap { uid, payload in
                guard uid != self.currentUserID else { return nil }
                guard let parsed = self.parseProfile(uid: uid, payload: payload) else { return nil }
                return parsed
            }
            self.isLoading = false
        } withCancel: { [weak self] error in
            self?.isLoading = false
            self?.errorMessage = error.localizedDescription
        }
    }

    func stopObserving() {
        if let usersRef, let handle {
            usersRef.removeObserver(withHandle: handle)
        }
        usersRef = nil
        handle = nil
    }

    private func parseProfile(uid: String, payload: [String: Any]) -> UserProfile? {
        UserProfile(id: uid, dictionary: payload)
    }
}

@MainActor
private final class FindLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var currentLocation: CLLocation?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func start() {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
            return
        }
        guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }
        manager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        start()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
}

struct FindView: View {
    let onLogout: () -> Void

    @AppStorage("selectedLanguage") private var selectedLanguageCode = "en"
    @AppStorage(LocaleCurrency.appStorageKey) private var storedCurrencyCode = ""
    @StateObject private var viewModel = FindViewModel()
    @StateObject private var locationManager = FindLocationManager()
    @StateObject private var favoriteFolderIdsObserver = FavoriteFolderIdsObserver()
    @StateObject private var messagesAppState = MessagesAppState()
    @State private var selectedTab = 2
    @State private var currentUser: UserProfile
    @StateObject private var livePaymentHistory: LivePaymentHistoryStore
    @State private var selectedProfile: UserProfile?
    /// When true on the Find tab, the profile list is replaced by the map.
    @State private var showsMapInsteadOfList = false
    @State private var listFilter: FindListFilter = .all
    @State private var geocodeCache: [String: CLLocationCoordinate2D] = [:]
    @State private var distanceByProfileID: [String: Double] = [:]
    /// `true` until the latest `recomputeDistances` finishes (avoids a flash of "unavailable" on first paint).
    @State private var isDistanceComputationRunning = true

    private let menuHeight: CGFloat = 34
    private let menuButtonSpacing: CGFloat = -40

    private var title: String {
        switch selectedTab {
        case 0: return t(.historyTitle)
        case 1: return t(.livePayTitle)
        case 4: return t(.messagesTitle)
        case 3: return t(.findTitleSettings)
        default: return t(.findTitleFolders)
        }
    }

    private func t(_ key: VikaL10n.Key) -> String {
        VikaL10n.t(key, languageCode: selectedLanguageCode)
    }

    /// Profiles after search + folder rules, then All / Favorites / Nearby.
    private var listProfiles: [UserProfile] {
        let base = viewModel.filteredProfiles
        switch listFilter {
        case .all:
            return base
        case .favorites:
            return base.filter { favoriteFolderIdsObserver.ids.contains($0.id) }
        case .nearby:
            return base.sorted { p1, p2 in
                let d1 = distanceByProfileID[p1.id] ?? Double.greatestFiniteMagnitude
                let d2 = distanceByProfileID[p2.id] ?? Double.greatestFiniteMagnitude
                if abs(d1 - d2) < 0.000_1 {
                    return p1.fullName.localizedCaseInsensitiveCompare(p2.fullName) == .orderedAscending
                }
                return d1 < d2
            }
        }
    }

    init(currentUser: UserProfile, onLogout: @escaping () -> Void) {
        self.onLogout = onLogout
        _currentUser = State(initialValue: currentUser)
        _livePaymentHistory = StateObject(wrappedValue: LivePaymentHistoryStore(userId: currentUser.id))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                if selectedTab == 4 {
                    MessagesView(selectedTab: $selectedTab)
                        .environmentObject(messagesAppState)
                        .environment(\.messagesLanguageCode, selectedLanguageCode)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if selectedTab == 0 {
                    HistoryView(historyStore: livePaymentHistory, languageCode: selectedLanguageCode)
                } else if selectedTab == 1 {
                    LivePayView(currentUser: currentUser, selectedTab: $selectedTab, historyStore: livePaymentHistory)
                } else if selectedTab == 3 {
                    SettingsView(
                        currentUser: currentUser,
                        onLogout: onLogout,
                        onProfileUpdated: { updatedProfile in
                            currentUser = updatedProfile
                        }
                    )
                } else {
                    if viewModel.isLoading {
                        ProgressView(t(.findLoadingUsers))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.filteredProfiles.isEmpty {
                        ContentUnavailableView(
                            t(.findNoResults),
                            systemImage: "person.2.slash",
                            description: Text(t(.findTryChangeFilter))
                        )
                    } else {
                        VStack(spacing: 0) {
                            Picker(selection: $listFilter) {
                                Text(t(.findFilterAll)).tag(FindListFilter.all)
                                Text(t(.findFilterFavorites)).tag(FindListFilter.favorites)
                                Text(t(.findFilterNearby)).tag(FindListFilter.nearby)
                            } label: {
                                EmptyView()
                            }
                            .pickerStyle(.segmented)
                            .tint(Color.appGreen)
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .padding(.bottom, 10)

                            if listProfiles.isEmpty {
                                ContentUnavailableView(
                                    t(.findNoResults),
                                    systemImage: listFilter == .favorites ? "star" : "person.2.slash",
                                    description: Text(
                                        listFilter == .favorites ? t(.findNoFavorites) : t(.findTryChangeFilter)
                                    )
                                )
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else if showsMapInsteadOfList {
                                FindMapView(
                                    profiles: listProfiles,
                                    currentUser: currentUser,
                                    languageCode: selectedLanguageCode,
                                    onSelect: { selectedProfile = $0 }
                                )
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 10) {
                                        ForEach(listProfiles) { profile in
                                            profileCard(profile)
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    selectedProfile = profile
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if selectedTab == 2 {
                        Button {
                            showsMapInsteadOfList.toggle()
                        } label: {
                            if showsMapInsteadOfList {
                                Label(t(.findList), systemImage: "list.bullet")
                            } else {
                                Label(t(.findMap), systemImage: "map")
                            }
                        }
                        .tint(Color.appGreen)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.headline)
                }
            }
            .onChange(of: selectedTab) { _, newValue in
                if newValue != 2 {
                    showsMapInsteadOfList = false
                }
            }
            .onChange(of: currentUser.id) { _, newId in
                favoriteFolderIdsObserver.start(currentUserId: newId)
            }
            .onAppear {
                viewModel.start(currentUser: currentUser)
                locationManager.start()
                favoriteFolderIdsObserver.start(currentUserId: currentUser.id)
                messagesAppState.startInboxListener()
            }
            .onDisappear {
                viewModel.stopObserving()
                favoriteFolderIdsObserver.stop()
                messagesAppState.stopInboxListener()
            }
            .alert(t(.errorTitle), isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button(t(.alertOK), role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                footerMenu
            }
            .sheet(item: $selectedProfile) { profile in
                NavigationStack {
                    UserDetailsView(user: profile, currentUser: currentUser)
                }
            }
            .sheet(isPresented: Binding(
                get: { messagesAppState.showingNewMessageNotification && !messagesAppState.newMessageSenderId.isEmpty },
                set: { if !$0 { messagesAppState.dismissNewMessageNotification() } }
            )) {
                NewMessageNotificationModal(
                    senderName: messagesAppState.newMessageSenderName,
                    senderProfilePhotoURL: messagesAppState.newMessageSenderPhotoURL,
                    onOpen: {
                        let senderId = messagesAppState.newMessageSenderId
                        messagesAppState.dismissNewMessageNotification()
                        selectedTab = 4
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                            messagesAppState.conversationToOpenSenderId = senderId
                        }
                    },
                    onLater: {
                        messagesAppState.dismissNewMessageNotification()
                    }
                )
                .environment(\.messagesLanguageCode, selectedLanguageCode)
                .presentationBackground(.clear)
            }
            .task(id: distanceComputationSignature) {
                isDistanceComputationRunning = true
                await recomputeDistances()
                isDistanceComputationRunning = false
            }
        }
    }

    private func profileCard(_ profile: UserProfile) -> some View {
        let isFolderAudience = viewModel.selectedAudience == .folders

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                profileThumbnail(for: profile)
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                if isFolderAudience {
                    ZStack(alignment: .topLeading) {
                        Text(profile.fullName)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 70,
                                alignment: Alignment(horizontal: .leading, vertical: .center)
                            )
                            .padding(.leading, 10)
                            .padding(.trailing, profile.chargingFee > 0 ? 108 : 0)

                        VStack {
                            Spacer(minLength: 0)
                            HStack {
                                Spacer(minLength: 0)
                                distanceBadge(for: profile)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 70)
                    }
                    .overlay(alignment: .topTrailing) {
                        chargingFeeTopLabel(for: profile)
                    }
                    .frame(maxWidth: .infinity, minHeight: 70)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .center, spacing: 8) {
                            Text(profile.fullName)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .layoutPriority(0)

                            Spacer(minLength: 0)

                            distanceBadge(for: profile)
                                .fixedSize(horizontal: true, vertical: false)
                                .layoutPriority(1)
                        }

                        Text(profile.email)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            if profile.showPhoneNumber {
                                infoChip(profile.phoneNumber, tint: .orange)
                            } else {
                                infoChip(t(.findPhoneHiddenShort), tint: .secondary)
                            }
                            infoChip(activityText(for: profile), tint: .orange)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(10)

            // Message is always available from Find (not only for favorites)—tap switches to Messages and opens the thread.
            Button {
                presentMessageConversation(for: profile)
            } label: {
                Label(t(.findMessage), systemImage: "message.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.appGreen.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder
    private func profileThumbnail(for profile: UserProfile) -> some View {
        if let imageURL = profile.profileImageURL,
           let url = URL(string: imageURL),
           !imageURL.isEmpty {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.appGreen.opacity(0.18))
                    .overlay {
                        ProgressView()
                            .tint(Color.appGreen)
                    }
            }
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.appGreen.opacity(0.18))
                .overlay {
                    VStack(spacing: 6) {
                        Image(systemName: roleSymbol(for: profile.role))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.appGreen)
                        Text(initials(for: profile))
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(Color.appGreen)
                    }
                }
        }
    }

    private func infoChip(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    /// Amount + ISO code + regional flag (uses app currency from Settings). Same pill style as `distanceBadge`, orange tint.
    @ViewBuilder
    private func chargingFeeTopLabel(for profile: UserProfile) -> some View {
        if profile.chargingFee > 0 {
            let code = LocaleCurrency.resolvedCode(storedOverride: storedCurrencyCode)
            let flag = CurrencyRegionFlag.flagEmoji(forCurrencyCode: code)
            HStack(spacing: 4) {
                Text(String(format: "%.2f", profile.chargingFee))
                    .font(.caption2.weight(.bold))
                Text(code.uppercased())
                    .font(.caption2.weight(.bold))
                if !flag.isEmpty {
                    Text(flag)
                        .font(.caption2)
                }
            }
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.9)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func distanceBadge(for profile: UserProfile) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Image(systemName: "location.fill")
                .font(.caption2.weight(.bold))
            Text(distanceText(for: profile))
                .font(.caption2.weight(.bold))
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .fixedSize(horizontal: true, vertical: true)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.appGreen.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .fixedSize(horizontal: true, vertical: true)
    }

    private func distanceText(for profile: UserProfile) -> String {
        if let km = distanceByProfileID[profile.id] {
            return String(format: "%.1f km away", km)
        }
        let addr = profile.address.trimmingCharacters(in: .whitespacesAndNewlines)
        if addr.isEmpty {
            return t(.findDistanceNoAddress)
        }
        if isDistanceComputationRunning {
            return t(.findDistanceCalculating)
        }
        return t(.findDistanceUnavailable)
    }

    private func initials(for profile: UserProfile) -> String {
        let first = profile.firstName.first.map(String.init) ?? ""
        let last = profile.lastName.first.map(String.init) ?? ""
        let value = (first + last).uppercased()
        return value.isEmpty ? "U" : value
    }

    private func activityText(for profile: UserProfile) -> String {
        guard let lastLoginAt = profile.lastLoginAt, lastLoginAt > 0 else {
            return t(.statusNew)
        }
        let secondsAgo = Date().timeIntervalSince1970 - (lastLoginAt / 1000)
        if secondsAgo < 3600 {
            return t(.statusActive)
        }
        let hours = Int(secondsAgo / 3600)
        return "\(hours)h ago"
    }

    /// SpectRoom-style: switch to Messages and open the thread (existing row or empty placeholder). The user sends the first real message from the composer—no auto-send that can fail on Firebase rules.
    private func presentMessageConversation(for profile: UserProfile) {
        selectedTab = 4
        let otherUid = profile.id
        Task { @MainActor in
            try? await messagesAppState.refreshMessageConversationsCache()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            messagesAppState.conversationToOpenSenderId = otherUid
        }
    }

    private var distanceComputationSignature: String {
        let ids = viewModel.filteredProfiles.map(\.id).sorted().joined(separator: "|")
        let lat = locationManager.currentLocation?.coordinate.latitude ?? 0
        let lon = locationManager.currentLocation?.coordinate.longitude ?? 0
        let currentUserAddress = currentUser.address.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(ids)-\(lat)-\(lon)-\(currentUserAddress)"
    }

    private func recomputeDistances() async {
        let origin = await distanceOriginLocation()
        guard let origin else {
            distanceByProfileID = [:]
            return
        }

        var next: [String: Double] = [:]
        for profile in viewModel.filteredProfiles {
            let address = profile.address.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !address.isEmpty else { continue }
            guard let coordinate = await coordinateForAddress(address) else { continue }

            let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let meters = origin.distance(from: target)
            next[profile.id] = meters / 1000
        }
        distanceByProfileID = next
    }

    private func distanceOriginLocation() async -> CLLocation? {
        if let deviceLocation = locationManager.currentLocation {
            return deviceLocation
        }

        let myAddress = currentUser.address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !myAddress.isEmpty else { return nil }
        guard let coordinate = await coordinateForAddress(myAddress) else { return nil }
        return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    private func coordinateForAddress(_ address: String) async -> CLLocationCoordinate2D? {
        if let cached = geocodeCache[address] {
            return cached
        }
        guard let request = MKGeocodingRequest(addressString: address) else { return nil }
        return await withCheckedContinuation { continuation in
            request.getMapItems { mapItems, _ in
                let coordinate = mapItems?.first?.location.coordinate
                if let coordinate {
                    Task { @MainActor in
                        geocodeCache[address] = coordinate
                    }
                }
                continuation.resume(returning: coordinate)
            }
        }
    }

    private func roleSymbol(for role: UserRole) -> String {
        switch role {
        case .folder: return "basket.fill"
        case .client: return "house.fill"
        case .user: return "person.fill"
        }
    }

    private var footerMenu: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20)
                    .fill(Color.white)
                    .frame(height: menuHeight)
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: -3)

                Rectangle()
                    .fill(Color.white)
                    .frame(height: 5)
            }

            HStack(spacing: menuButtonSpacing) {
                FooterMenuButton(icon: "list.bullet.rectangle.fill", label: t(.tabHistory), isSelected: selectedTab == 0) { selectedTab = 0 }
                FooterMenuButton(icon: "clock.fill", label: t(.livePayTitle), isSelected: selectedTab == 1) { selectedTab = 1 }
                FooterMenuButton(icon: "magnifyingglass", label: t(.tabFind), isSelected: selectedTab == 2) { selectedTab = 2 }
                FooterMenuButton(icon: "message.fill", label: t(.tabMessages), isSelected: selectedTab == 4) { selectedTab = 4 }
                FooterMenuButton(icon: "gearshape.fill", label: t(.tabSettings), isSelected: selectedTab == 3) { selectedTab = 3 }
            }
            .padding(.top, 20)
            .frame(height: menuHeight)
        }
        .ignoresSafeArea(edges: .bottom)
        .background(Color.white)
    }
}

private struct FooterMenuButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Text(label)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FindView(
        currentUser: UserProfile(
            id: "1",
            firstName: "Ava",
            lastName: "Folder",
            phoneNumber: "555-1000",
            email: "ava@example.com",
            address: "Main St 10",
            profileImageURL: nil,
            role: .folder,
            createdAt: nil,
            updatedAt: nil,
            lastLoginAt: nil
        ),
        onLogout: {}
    )
}
