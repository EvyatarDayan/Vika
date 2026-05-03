//
//  ProfileView.swift
//  Vika
//

import SwiftUI
import PhotosUI
import MapKit
import Combine

@MainActor
private final class AddressAutocompleteModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var completions: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address]
    }

    func updateQuery(_ query: String) {
        completer.queryFragment = query
    }

    func clear() {
        completions = []
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        completions = []
    }
}

private struct GallerySlot: Identifiable {
    let id: String
    enum Kind {
        case remote(String)
        case local(Data)
    }
    var kind: Kind

    static func remote(_ url: String) -> GallerySlot {
        GallerySlot(id: url, kind: .remote(url))
    }

    static func local(_ data: Data) -> GallerySlot {
        GallerySlot(id: UUID().uuidString, kind: .local(data))
    }
}

private let galleryMaxPhotos = 5
/// Shared corner radius for gallery thumbnails and the Add tile (matches grid cell size).
private let galleryThumbCornerRadius: CGFloat = 12
/// Smaller than full-width÷3: adaptive grid packs more columns with this minimum cell width.
private let galleryGridMinCellWidth: CGFloat = 72
private let galleryGridMaxCellWidth: CGFloat = 96

struct ProfileView: View {
    let profile: UserProfile
    let onUpdated: (UserProfile) -> Void

    @Environment(\.dismiss) private var dismiss

    @AppStorage("selectedLanguage") private var selectedLanguageCode = "en"

    @State private var firstName: String
    @State private var lastName: String
    @State private var phoneNumber: String
    @State private var address: String
    @State private var savedFirstName: String
    @State private var savedLastName: String
    @State private var savedPhoneNumber: String
    @State private var savedAddress: String
    @State private var showPhoneNumber: Bool
    @State private var showAddress: Bool
    @State private var isFolder: Bool
    @State private var chargingFee: String
    @State private var savedShowPhoneNumber: Bool
    @State private var savedShowAddress: Bool
    @State private var savedIsFolder: Bool
    @State private var savedChargingFee: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingPhotoSourceSheet = false
    @State private var showingAvatarSheet = false
    @State private var profileImageData: Data?
    @State private var gallerySlots: [GallerySlot]
    @State private var savedGalleryURLs: [String]
    @State private var galleryAddPickerItem: PhotosPickerItem?
    @State private var selectedGalleryIndex = 0
    @State private var isGalleryViewerPresented = false
    @State private var isUpdating = false
    @State private var saveErrorMessage: String?
    @StateObject private var addressAutocomplete = AddressAutocompleteModel()
    @FocusState private var isAddressFocused: Bool

    init(profile: UserProfile, onUpdated: @escaping (UserProfile) -> Void) {
        self.profile = profile
        self.onUpdated = onUpdated
        _firstName = State(initialValue: profile.firstName)
        _lastName = State(initialValue: profile.lastName)
        _phoneNumber = State(initialValue: profile.phoneNumber)
        _address = State(initialValue: profile.address)
        _savedFirstName = State(initialValue: profile.firstName)
        _savedLastName = State(initialValue: profile.lastName)
        _savedPhoneNumber = State(initialValue: profile.phoneNumber)
        _savedAddress = State(initialValue: profile.address)
        _showPhoneNumber = State(initialValue: profile.showPhoneNumber)
        _showAddress = State(initialValue: profile.showAddress)
        _isFolder = State(initialValue: profile.isFolder)
        _chargingFee = State(initialValue: profile.chargingFee > 0 ? String(format: "%.2f", profile.chargingFee) : "")
        _savedShowPhoneNumber = State(initialValue: profile.showPhoneNumber)
        _savedShowAddress = State(initialValue: profile.showAddress)
        _savedIsFolder = State(initialValue: profile.isFolder)
        _savedChargingFee = State(initialValue: profile.chargingFee > 0 ? String(format: "%.2f", profile.chargingFee) : "")
        let urls = profile.galleryImageURLs
        _savedGalleryURLs = State(initialValue: urls)
        _gallerySlots = State(initialValue: urls.map { GallerySlot.remote($0) })
    }

    private func t(_ key: VikaL10n.Key) -> String {
        VikaL10n.t(key, languageCode: selectedLanguageCode)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Keep profile photo fixed; only fields/gallery scroll.
            profilePhotoCard
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 22) {
                    fieldSection(title: t(.fieldFirstName)) {
                        editableField(t(.placeholderFirstName), text: $firstName, contentType: .givenName, keyboard: .default, enabled: true)
                    }

                    fieldSection(title: t(.fieldLastName)) {
                        editableField(t(.placeholderLastName), text: $lastName, contentType: .familyName, keyboard: .default, enabled: true)
                    }

                    fieldSection(title: t(.fieldEmail)) {
                        editableField(t(.placeholderEmail), text: .constant(profile.email), contentType: .emailAddress, keyboard: .emailAddress, enabled: false)
                    }

                    fieldSection(title: t(.fieldPhone)) {
                        VStack(alignment: .leading, spacing: 8) {
                            editableField(t(.placeholderPhone), text: $phoneNumber, contentType: .telephoneNumber, keyboard: .phonePad, enabled: true)
                            CompactLabeledToggleRow(isOn: $showPhoneNumber, label: t(.showPhoneNumberToggle))
                        }
                    }

                    fieldSection(title: t(.fieldAddress)) {
                        VStack(spacing: 8) {
                            TextField(t(.placeholderAddress), text: $address)
                                .textContentType(.fullStreetAddress)
                                .keyboardType(.default)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .focused($isAddressFocused)
                                .onChange(of: address) { _, newValue in
                                    let query = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if query.isEmpty {
                                        addressAutocomplete.clear()
                                    } else {
                                        addressAutocomplete.updateQuery(query)
                                    }
                                }

                            if isAddressFocused && !addressAutocomplete.completions.isEmpty {
                                VStack(spacing: 0) {
                                    let topCompletions = Array(addressAutocomplete.completions.prefix(5))
                                    ForEach(Array(topCompletions.enumerated()), id: \.offset) { index, completion in
                                        Button {
                                            selectAddressCompletion(completion)
                                        } label: {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(completion.title)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.primary)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                if !completion.subtitle.isEmpty {
                                                    Text(completion.subtitle)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                        }
                                        .buttonStyle(.plain)

                                        if index < topCompletions.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }

                            Text(t(.addressPrivacy))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            CompactLabeledToggleRow(isOn: $showAddress, label: t(.showAddressToggle))
                        }
                    }

                    fieldSection(title: t(.isFolderToggle)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $isFolder) {
                                Text(t(.isFolderToggle))
                                    .font(.footnote)
                            }
                            .tint(Color.appGreen)

                            if isFolder {
                                chargingFeeField()
                            }
                        }
                    }

                    }

                    galleryCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
        }
        .background(Color(.systemGroupedBackground))
        .overlay {
            if isUpdating {
                ZStack {
                    Color.black.opacity(0.12)
                        .ignoresSafeArea()

                    ProgressView()
                        .scaleEffect(1.2)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                }
            }
        }
        .allowsHitTesting(!isUpdating)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(t(.profileTitle))
                    .font(.headline)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Group {
                    if hasUnsavedChanges {
                        Button(t(.profileUpdate), action: updateTapped)
                            .foregroundStyle(canUpdate ? Color.appGreen : .gray)
                            .disabled(!canUpdate)
                    } else {
                        Button(t(.profileClose)) {
                            dismiss()
                        }
                        .foregroundStyle(Color.appGreen)
                    }
                }
                .id("\(hasUnsavedChanges)-\(gallerySlots.count)-\(galleryIsDirty)")
            }
        }
        .alert(t(.errorTitle), isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button(t(.alertOK), role: .cancel) {}
        } message: {
            Text(saveErrorMessage ?? "")
        }
        .onChange(of: selectedPhoto) { _, newValue in
            guard let newValue else { return }
            showingPhotoSourceSheet = false
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let compressed = image.jpegData(compressionQuality: 0.6) {
                    await MainActor.run {
                        profileImageData = compressed
                        selectedPhoto = nil
                    }
                }
            }
        }
        .onChange(of: galleryAddPickerItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let compressed = image.jpegData(compressionQuality: 0.6) {
                    await MainActor.run {
                        if gallerySlots.count < galleryMaxPhotos {
                            gallerySlots.append(GallerySlot.local(compressed))
                        }
                        galleryAddPickerItem = nil
                    }
                }
            }
        }
        .sheet(isPresented: $isGalleryViewerPresented) {
            PhotoGalleryViewer(
                items: galleryViewerItems,
                selectedIndex: $selectedGalleryIndex,
                onSetAsProfile: setSelectedViewerPhotoAsProfile,
                onClose: { isGalleryViewerPresented = false }
            )
        }
        .sheet(isPresented: $showingPhotoSourceSheet) {
            ChooseProfilePhotoSourceSheet(
                titleText: t(.chooseProfilePhotoTitle),
                chooseFromAvatarText: t(.chooseFromAvatarOption),
                chooseFromLibraryText: t(.chooseFromLibraryOption),
                selectedPhoto: $selectedPhoto,
                showingPhotoSourceSheet: $showingPhotoSourceSheet,
                showingAvatarSheet: $showingAvatarSheet
            )
            .presentationDetents([.height(190)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAvatarSheet) {
            AvatarSelectionModal(
                titleText: t(.chooseAvatarTitle),
                avatarAssetNames: avatarAssetNames,
                onPick: { assetName in setProfilePhotoFromAvatarAsset(assetName) },
                showingAvatarSheet: $showingAvatarSheet
            )
        }
    }

    private var profilePhotoCard: some View {
        HStack {
            Spacer(minLength: 0)
            profileImagePicker
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var galleryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(t(.profileGalleryTitle))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            let columns = [
                GridItem(
                    .adaptive(minimum: galleryGridMinCellWidth, maximum: galleryGridMaxCellWidth),
                    spacing: 8
                )
            ]

            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(Array(gallerySlots.enumerated()), id: \.element.id) { index, slot in
                    galleryTile(slot: slot, index: index)
                }

                if gallerySlots.count < galleryMaxPhotos {
                    galleryAddTile
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    /// Square cell matching the Add tile: image is center-cropped to fill; intrinsic size cannot grow the grid.
    private func galleryTile(slot: GallerySlot, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Button {
                selectedGalleryIndex = index
                isGalleryViewerPresented = true
            } label: {
                gallerySquareChrome {
                    galleryTileMedia(slot: slot)
                }
            }
            .buttonStyle(.plain)

            Button {
                gallerySlots.removeAll { $0.id == slot.id }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Color.red, in: Circle())
            }
            .buttonStyle(.plain)
            .offset(x: -7, y: 5)
        }
        .frame(maxWidth: .infinity)
    }

    /// Same outer square as `galleryAddTile` (full column width × width).
    private func gallerySquareChrome<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }
            .overlay(
                RoundedRectangle(cornerRadius: galleryThumbCornerRadius, style: .continuous)
                    .strokeBorder(Color.appGreen.opacity(0.45), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: galleryThumbCornerRadius, style: .continuous))
    }

    @ViewBuilder
    private func galleryTileMedia(slot: GallerySlot) -> some View {
        switch slot.kind {
        case .remote(let urlString):
            if let url = URL(string: urlString), !urlString.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.appGreen.opacity(0.1))
                    case .failure:
                        RoundedRectangle(cornerRadius: galleryThumbCornerRadius, style: .continuous)
                            .fill(Color.appGreen.opacity(0.18))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                RoundedRectangle(cornerRadius: galleryThumbCornerRadius, style: .continuous)
                    .fill(Color.appGreen.opacity(0.18))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        case .local(let data):
            if let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: galleryThumbCornerRadius, style: .continuous)
                    .fill(Color.appGreen.opacity(0.18))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var galleryAddTile: some View {
        PhotosPicker(selection: $galleryAddPickerItem, matching: .images) {
            gallerySquareChrome {
                ZStack {
                    RoundedRectangle(cornerRadius: galleryThumbCornerRadius, style: .continuous)
                        .fill(Color.blue.opacity(0.05))
                    RoundedRectangle(cornerRadius: galleryThumbCornerRadius, style: .continuous)
                        .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                    VStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.blue)
                        Text(t(.profileGalleryAdd))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.blue)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .buttonStyle(.plain)
    }

    private var galleryViewerItems: [GalleryImageItem] {
        gallerySlots.map { slot in
            switch slot.kind {
            case .remote(let url):
                return GalleryImageItem(id: slot.id, urlString: url, imageData: nil)
            case .local(let data):
                return GalleryImageItem.local(id: slot.id, data: data)
            }
        }
    }

    @ViewBuilder
    private func galleryThumbnail(for item: GalleryImageItem) -> some View {
        if let data = item.imageData, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else if let urlString = item.urlString, let url = URL(string: urlString), !urlString.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.appGreen.opacity(0.1))
                case .failure:
                    RoundedRectangle(cornerRadius: galleryThumbCornerRadius, style: .continuous)
                        .fill(Color.appGreen.opacity(0.18))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            RoundedRectangle(cornerRadius: galleryThumbCornerRadius, style: .continuous)
                .fill(Color.appGreen.opacity(0.18))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var profileImage: some View {
        Group {
            if let uiImage = currentUIImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let urlString = profile.profileImageURL, let url = URL(string: urlString), !urlString.isEmpty {
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
                        ZStack {
                            Circle()
                                .fill(Color.appGreen.opacity(0.2))
                            Text(initials)
                                .font(.title.weight(.bold))
                                .foregroundStyle(Color.appGreen)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                ZStack {
                    Circle()
                        .fill(Color.appGreen.opacity(0.2))
                    Text(initials)
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.appGreen)
                }
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(Circle())
    }

    private var profileImagePicker: some View {
        Button {
            showingPhotoSourceSheet = true
        } label: {
            ZStack(alignment: .bottomTrailing) {
                profileImage

                Circle()
                    .fill(Color.appGreen)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    )
                    .offset(x: 4, y: 2)
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private struct ChooseProfilePhotoSourceSheet: View {
        let titleText: String
        let chooseFromAvatarText: String
        let chooseFromLibraryText: String
        @Binding var selectedPhoto: PhotosPickerItem?
        @Binding var showingPhotoSourceSheet: Bool
        @Binding var showingAvatarSheet: Bool

        var body: some View {
            VStack(spacing: 14) {
                Text(titleText)
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(spacing: 10) {
                    Button {
                        showingPhotoSourceSheet = false
                        showingAvatarSheet = true
                    } label: {
                        Text(chooseFromAvatarText)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Text(chooseFromLibraryText)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .tint(.black)
                }
            }
            .padding(16)
        }
    }

    private struct AvatarSelectionModal: View {
        let titleText: String
        let avatarAssetNames: [String]
        let onPick: (String) -> Void
        @Binding var showingAvatarSheet: Bool

        private var columns: [GridItem] {
            [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
        }

        var body: some View {
            VStack(spacing: 16) {
                Text(titleText)
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .center)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(avatarAssetNames, id: \.self) { assetName in
                            Button {
                                onPick(assetName)
                                showingAvatarSheet = false
                            } label: {
                                Image(assetName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Color.appGreen, lineWidth: 3)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                }
            }
            .padding(.top, 8)
        }
    }

    private var avatarAssetNames: [String] {
        (1...10).map { "Avatar\($0)" }
    }

    private func setProfilePhotoFromAvatarAsset(_ assetName: String) {
        guard let uiImage = UIImage(named: assetName) else { return }
        let compressed = uiImage.jpegData(compressionQuality: 0.6) ?? uiImage.pngData()
        guard let data = compressed else { return }
        profileImageData = data
        selectedPhoto = nil
    }

    private var currentUIImage: UIImage? {
        if let profileImageData, let image = UIImage(data: profileImageData) {
            return image
        }
        return nil
    }

    private func setProfilePhoto(from slot: GallerySlot) {
        switch slot.kind {
        case .local(let data):
            profileImageData = data
        case .remote(let urlString):
            setProfilePhoto(fromRemoteURL: urlString)
        }
    }

    private func setProfilePhoto(from item: GalleryImageItem) {
        if let data = item.imageData {
            profileImageData = data
            return
        }
        if let urlString = item.urlString {
            setProfilePhoto(fromRemoteURL: urlString)
        }
    }

    private func setSelectedViewerPhotoAsProfile() {
        guard galleryViewerItems.indices.contains(selectedGalleryIndex) else { return }
        setProfilePhoto(from: galleryViewerItems[selectedGalleryIndex])
    }

    private func setProfilePhoto(fromRemoteURL urlString: String) {
        guard let url = URL(string: urlString), !urlString.isEmpty else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data),
                      let compressed = image.jpegData(compressionQuality: 0.6) else {
                    throw URLError(.cannotDecodeContentData)
                }
                await MainActor.run {
                    profileImageData = compressed
                }
            } catch {
                await MainActor.run {
                    saveErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private var initials: String {
        let first = firstName.first.map(String.init) ?? ""
        let last = lastName.first.map(String.init) ?? ""
        let value = (first + last).uppercased()
        return value.isEmpty ? "U" : value
    }

    private var hasUnsavedChanges: Bool {
        let cleanedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedChargingFee = chargingFee.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleanedFirstName != savedFirstName
            || cleanedLastName != savedLastName
            || cleanedPhone != savedPhoneNumber
            || cleanedAddress != savedAddress
            || showPhoneNumber != savedShowPhoneNumber
            || showAddress != savedShowAddress
            || isFolder != savedIsFolder
            || cleanedChargingFee != savedChargingFee
            || profileImageData != nil
            || galleryIsDirty
    }

    private var galleryIsDirty: Bool {
        for slot in gallerySlots {
            switch slot.kind {
            case .local:
                return true
            case .remote:
                break
            }
        }
        let remoteOrder = gallerySlots.compactMap { slot -> String? in
            if case .remote(let u) = slot.kind { return u }
            return nil
        }
        return remoteOrder != savedGalleryURLs
    }

    /// First, last, and phone must all be non-empty when saving edited text fields.
    private var hasRequiredFields: Bool {
        let basicFieldsValid = !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard basicFieldsValid else { return false }

        if isFolder {
            let cleanedFee = chargingFee.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let fee = Double(cleanedFee), fee > 0 else { return false }
        }
        return true
    }

    private var canUpdate: Bool {
        guard !isUpdating else { return false }
        guard hasUnsavedChanges else { return false }

        if hasRequiredFields {
            return true
        }

        // Gallery / profile-photo-only: allow save when first & last name are filled, text matches
        // what was last saved, and phone may stay empty (hasRequiredFields would block otherwise).
        let cleanedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedChargingFee = chargingFee.trimmingCharacters(in: .whitespacesAndNewlines)

        let textMatchesSaved =
            cleanedFirstName == savedFirstName
                && cleanedLastName == savedLastName
                && cleanedPhone == savedPhoneNumber
                && cleanedAddress == savedAddress
                && showPhoneNumber == savedShowPhoneNumber
                && showAddress == savedShowAddress
                && isFolder == savedIsFolder
                && cleanedChargingFee == savedChargingFee

        let mediaDirty = profileImageData != nil || galleryIsDirty
        let namesPresent = !cleanedFirstName.isEmpty && !cleanedLastName.isEmpty

        return mediaDirty && textMatchesSaved && namesPresent
    }

    private func fieldSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            content()
        }
    }

    private func chargingFeeField() -> some View {
        HStack(spacing: 10) {
            TextField(t(.placeholderChargingFee), text: $chargingFee)
                .keyboardType(.decimalPad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .frame(maxWidth: .infinity, alignment: .leading)

            CurrencyCodeFlagLabel(flagFont: .title3, codeFont: .subheadline.weight(.semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func editableField(
        _ placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType?,
        keyboard: UIKeyboardType,
        enabled: Bool
    ) -> some View {
        TextField(placeholder, text: text)
            .textContentType(contentType)
            .keyboardType(keyboard)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .disabled(!enabled)
            .opacity(enabled ? 1 : 0.7)
    }

    private func selectAddressCompletion(_ completion: MKLocalSearchCompletion) {
        let formatted = [completion.title, completion.subtitle]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        address = formatted
        addressAutocomplete.clear()
        isAddressFocused = false
    }

    private func updateTapped() {
        guard canUpdate else { return }

        saveErrorMessage = nil

        let cleanedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedChargingFee = chargingFee.trimmingCharacters(in: .whitespacesAndNewlines)
        let chargingFeeValue = Double(cleanedChargingFee) ?? 0

        isUpdating = true

        Task {
            do {
                let galleryEntries: [GalleryProfileEntry] = gallerySlots.map { slot in
                    switch slot.kind {
                    case .remote(let url):
                        return .keepRemoteURL(url)
                    case .local(let data):
                        return .uploadNew(data)
                    }
                }

                let (uploadedImageURL, galleryURLs) = try await AuthService().updateUserProfile(
                    uid: profile.id,
                    firstName: cleanedFirstName,
                    lastName: cleanedLastName,
                    phoneNumber: cleanedPhone,
                    address: cleanedAddress,
                    showPhoneNumber: showPhoneNumber,
                    showAddress: showAddress,
                    isFolder: isFolder,
                    chargingFee: chargingFeeValue,
                    profileImageData: profileImageData,
                    galleryEntries: galleryEntries,
                    previouslySavedGalleryURLs: savedGalleryURLs
                )

                await MainActor.run {
                    let optimisticProfile = UserProfile(
                        id: profile.id,
                        firstName: cleanedFirstName,
                        lastName: cleanedLastName,
                        phoneNumber: cleanedPhone,
                        email: profile.email,
                        address: cleanedAddress,
                        showPhoneNumber: showPhoneNumber,
                        showAddress: showAddress,
                        isFolder: isFolder,
                        chargingFee: chargingFeeValue,
                        profileImageURL: uploadedImageURL ?? profile.profileImageURL,
                        galleryImageURLs: galleryURLs,
                        role: profile.role,
                        createdAt: profile.createdAt,
                        updatedAt: profile.updatedAt,
                        lastLoginAt: profile.lastLoginAt
                    )
                    isUpdating = false
                    onUpdated(optimisticProfile)
                    firstName = cleanedFirstName
                    lastName = cleanedLastName
                    phoneNumber = cleanedPhone
                    address = cleanedAddress
                    savedFirstName = cleanedFirstName
                    savedLastName = cleanedLastName
                    savedPhoneNumber = cleanedPhone
                    savedAddress = cleanedAddress
                    savedShowPhoneNumber = showPhoneNumber
                    savedShowAddress = showAddress
                    savedIsFolder = isFolder
                    savedChargingFee = cleanedChargingFee
                    savedGalleryURLs = galleryURLs
                    gallerySlots = galleryURLs.map { GallerySlot.remote($0) }
                    profileImageData = nil
                    selectedPhoto = nil
                }

                // Best-effort refresh: if backend data is temporarily malformed, keep optimistic
                // saved state and avoid showing an error popup after a successful save.
                if let refreshed = try? await AuthService().fetchUserProfile(uid: profile.id) {
                    await MainActor.run {
                        onUpdated(refreshed)
                        showPhoneNumber = refreshed.showPhoneNumber
                        showAddress = refreshed.showAddress
                        savedShowPhoneNumber = refreshed.showPhoneNumber
                        savedShowAddress = refreshed.showAddress
                        isFolder = refreshed.isFolder
                        savedIsFolder = refreshed.isFolder
                        chargingFee = refreshed.chargingFee > 0 ? String(format: "%.2f", refreshed.chargingFee) : ""
                        savedChargingFee = chargingFee
                        savedGalleryURLs = refreshed.galleryImageURLs
                        gallerySlots = refreshed.galleryImageURLs.map { GallerySlot.remote($0) }
                    }
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    saveErrorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    ProfileView(
        profile: UserProfile(
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
        onUpdated: { _ in }
    )
}
