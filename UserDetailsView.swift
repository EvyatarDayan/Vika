//
//  UserDetailsView.swift
//  Vika
//

import SwiftUI
import Combine
import CoreLocation
import MapKit
import FirebaseDatabase

private let profileGalleryThumbCornerRadius: CGFloat = 12
private let profileGalleryGridMinCellWidth: CGFloat = 72
private let profileGalleryGridMaxCellWidth: CGFloat = 96

@MainActor
private final class DistanceLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
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

@MainActor
private final class FolderFavoriteObserver: ObservableObject {
    @Published var isFavorite: Bool = false

    private var ref: DatabaseReference?
    private var handle: DatabaseHandle?

    func start(currentUserId: String, folderUserId: String) {
        stop()
        let r = Database.database().reference()
            .child("users")
            .child(currentUserId)
            .child("favoriteFolderIds")
            .child(folderUserId)
        ref = r
        handle = r.observe(.value) { [weak self] snapshot in
            Task { @MainActor in
                self?.isFavorite = Self.snapshotIsFavorite(snapshot)
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

    private static func snapshotIsFavorite(_ snapshot: DataSnapshot) -> Bool {
        if snapshot.value is NSNull { return false }
        if let b = snapshot.value as? Bool { return b }
        if let n = snapshot.value as? NSNumber { return n.boolValue }
        return false
    }
}

struct UserDetailsView: View {
    let user: UserProfile
    let currentUser: UserProfile
    @AppStorage("selectedLanguage") private var selectedLanguageCode = "en"
    @State private var selectedGalleryIndex = 0
    @State private var isGalleryViewerPresented = false
    @State private var isTogglingFavorite = false
    @State private var showFavoriteAddedToast = false
    @State private var favoriteToastDismissTask: Task<Void, Never>?

    @StateObject private var folderFavoriteObserver = FolderFavoriteObserver()
    @StateObject private var distanceLocationManager = DistanceLocationManager()
    @State private var distanceKm: Double?
    @State private var geocodeCache: [String: CLLocationCoordinate2D] = [:]

    private func t(_ key: VikaL10n.Key) -> String {
        VikaL10n.t(key, languageCode: selectedLanguageCode)
    }

    private var canFavoriteFolderProfile: Bool {
        user.id != currentUser.id
    }

    private var toastDisplayFirstName: String {
        let trimmed = user.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let parts = user.fullName.split(separator: " ")
        if let first = parts.first { return String(first) }
        return user.fullName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Keep header fixed (won't scroll with the rest of the fields).
            profileHeader
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    detailSection(title: t(.fieldFullName), value: user.fullName)
                    detailSection(title: t(.fieldEmail), value: user.email)
                    detailSection(
                        title: t(.fieldPhone),
                        value: phoneDisplayValue
                    )
                    if user.isFolder {
                        chargingFeeDetailSection()
                    }
                    detailSection(
                        title: t(.fieldAddress),
                        value: addressDisplayValue
                    )

                    if !user.galleryImageURLs.isEmpty {
                        gallerySection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .overlay(alignment: .top) {
            if showFavoriteAddedToast {
                Text(String(format: t(.profileFavoriteAddedToast), toastDisplayFirstName))
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(duration: 0.35), value: showFavoriteAddedToast)
        .navigationTitle(user.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if canFavoriteFolderProfile {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await toggleFolderFavorite() }
                    } label: {
                        Image("starPlus")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(folderFavoriteObserver.isFavorite ? Color.appGreen : Color.primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(isTogglingFavorite)
                    .accessibilityLabel(Text(t(.profileFavoriteFolder)))
                    .accessibilityAddTraits(folderFavoriteObserver.isFavorite ? .isSelected : AccessibilityTraits())
                }
            }
        }
        .onAppear {
            distanceLocationManager.start()
            if canFavoriteFolderProfile {
                folderFavoriteObserver.start(currentUserId: currentUser.id, folderUserId: user.id)
            }
        }
        .onDisappear {
            favoriteToastDismissTask?.cancel()
            favoriteToastDismissTask = nil
            folderFavoriteObserver.stop()
        }
        .sheet(isPresented: $isGalleryViewerPresented) {
            PhotoGalleryViewer(
                items: galleryViewerItems,
                selectedIndex: $selectedGalleryIndex,
                onSetAsProfile: nil,
                onClose: { isGalleryViewerPresented = false }
            )
        }
        .task(id: distanceComputationSignature) {
            await recomputeDistanceKm()
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 6) {
            Group {
                if let profileImageURL = user.profileImageURL,
                   let url = URL(string: profileImageURL),
                   !profileImageURL.isEmpty {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.appGreen.opacity(0.12))
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.appGreen.opacity(0.18))
                        Text(initials)
                            .font(.title.weight(.bold))
                            .foregroundStyle(Color.appGreen)
                    }
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(Circle())

            if let distanceKm {
                distanceBadgeView(distanceKm: distanceKm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private var distanceComputationSignature: String {
        let targetAddress = user.address.trimmingCharacters(in: .whitespacesAndNewlines)
        let originAddress = currentUser.address.trimmingCharacters(in: .whitespacesAndNewlines)
        let lat = distanceLocationManager.currentLocation?.coordinate.latitude ?? 0
        let lon = distanceLocationManager.currentLocation?.coordinate.longitude ?? 0
        return "\(targetAddress)-\(originAddress)-\(lat)-\(lon)"
    }

    @MainActor
    private func recomputeDistanceKm() async {
        let targetAddress = user.address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !targetAddress.isEmpty else {
            distanceKm = nil
            return
        }

        let origin = await distanceOriginLocation()
        guard let origin else {
            distanceKm = nil
            return
        }

        guard let targetCoord = await coordinateForAddress(targetAddress) else {
            distanceKm = nil
            return
        }

        let target = CLLocation(latitude: targetCoord.latitude, longitude: targetCoord.longitude)
        distanceKm = origin.distance(from: target) / 1000
    }

    private func distanceOriginLocation() async -> CLLocation? {
        if let deviceLocation = distanceLocationManager.currentLocation {
            return deviceLocation
        }

        let originAddress = currentUser.address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !originAddress.isEmpty else { return nil }
        guard let coordinate = await coordinateForAddress(originAddress) else { return nil }
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

    private func distanceBadgeView(distanceKm: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "location.fill")
                .font(.caption2.weight(.bold))
            Text(String(format: "%.1f km away", distanceKm))
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(Color.appGreen)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.appGreen.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var phoneDisplayValue: String {
        if user.showPhoneNumber {
            return user.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? t(.detailsNotProvided)
                : user.phoneNumber
        }
        let preferredName = user.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackName = user.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let visibleName = preferredName.isEmpty ? fallbackName : preferredName
        return String(format: t(.detailsPhoneHiddenByUser), visibleName)
    }

    private var addressDisplayValue: String {
        if user.showAddress {
            return user.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? t(.detailsNotProvided)
                : user.address
        }
        let preferredName = user.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackName = user.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let visibleName = preferredName.isEmpty ? fallbackName : preferredName
        return String(format: t(.detailsAddressHiddenByUser), visibleName)
    }

    private var chargingFeeDisplayValue: String {
        guard user.chargingFee > 0 else { return t(.detailsNotProvided) }
        return String(format: "%.2f", user.chargingFee)
    }

    private func toggleFolderFavorite() async {
        guard !isTogglingFavorite else { return }
        isTogglingFavorite = true
        defer { isTogglingFavorite = false }
        let newValue = !folderFavoriteObserver.isFavorite
        do {
            try await AuthService().setFolderFavorite(
                currentUserId: currentUser.id,
                folderUserId: user.id,
                isFavorite: newValue
            )
            if newValue {
                favoriteToastDismissTask?.cancel()
                withAnimation(.spring(duration: 0.35)) {
                    showFavoriteAddedToast = true
                }
                favoriteToastDismissTask = Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showFavoriteAddedToast = false
                        }
                    }
                }
            }
        } catch {
            // Observer stays aligned with server state.
        }
    }

    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(t(.profileGalleryTitle))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            let columns = [
                GridItem(
                    .adaptive(minimum: profileGalleryGridMinCellWidth, maximum: profileGalleryGridMaxCellWidth),
                    spacing: 8
                )
            ]
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(Array(galleryViewerItems.enumerated()), id: \.offset) { index, item in
                    Button {
                        selectedGalleryIndex = index
                        isGalleryViewerPresented = true
                    } label: {
                        galleryThumbnail(for: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var initials: String {
        let first = user.firstName.first.map(String.init) ?? ""
        let last = user.lastName.first.map(String.init) ?? ""
        let value = (first + last).uppercased()
        return value.isEmpty ? "U" : value
    }

    private var galleryViewerItems: [GalleryImageItem] {
        var items: [GalleryImageItem] = []

        let profileURL = user.profileImageURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let profileURL, !profileURL.isEmpty {
            items.append(
                GalleryImageItem(id: "profile-main-photo", urlString: profileURL, imageData: nil)
            )
        }

        // Sometimes the backend may also include the profile image inside `galleryImageURLs`.
        // Avoid showing it twice in "My Photos".
        let filteredGalleryURLs = user.galleryImageURLs.filter { raw in
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let profileURL else { return !trimmed.isEmpty }
            return !trimmed.isEmpty && trimmed != profileURL
        }

        items.append(contentsOf: filteredGalleryURLs.map { GalleryImageItem.remote($0) })
        return items
    }

    @ViewBuilder
    private func galleryThumbnail(for item: GalleryImageItem) -> some View {
        if let urlString = item.urlString, let url = URL(string: urlString), !urlString.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.appGreen.opacity(0.1))
                case .failure:
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.appGreen.opacity(0.18))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: profileGalleryThumbCornerRadius, style: .continuous)
                    .strokeBorder(Color.appGreen.opacity(0.45), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: profileGalleryThumbCornerRadius, style: .continuous))
        }
    }

    private func chargingFeeDetailSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(t(.fieldChargingFee))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(alignment: .center, spacing: 12) {
                Text(chargingFeeDisplayValue)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if user.chargingFee > 0 {
                    CurrencyCodeFlagLabel(flagFont: .title3, codeFont: .subheadline.weight(.semibold))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func detailSection(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

#Preview {
    NavigationStack {
        UserDetailsView(
            user: UserProfile(
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
            currentUser: UserProfile(
                id: "me",
                firstName: "Me",
                lastName: "",
                phoneNumber: "",
                email: "me@example.com",
                address: "Main St 10",
                profileImageURL: nil,
                role: .client,
                createdAt: nil,
                updatedAt: nil,
                lastLoginAt: nil
            )
        )
    }
}
