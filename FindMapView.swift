//
//  FindMapView.swift
//  Vika
//

import Combine
import CoreLocation
import MapKit
import SwiftUI

private struct ProfileMapPin: Identifiable {
    let id: String
    let profile: UserProfile
    let coordinate: CLLocationCoordinate2D
    let isCurrentUser: Bool
}

@MainActor
private final class FindMapGeocoder: ObservableObject {
    @Published private(set) var pins: [ProfileMapPin] = []
    @Published private(set) var isLoading = false

    func load(profiles: [UserProfile], currentUser: UserProfile) async {
        isLoading = true
        pins = []

        let profilesWithAddress = profiles.filter { !$0.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let currentUserAddress = currentUser.address.trimmingCharacters(in: .whitespacesAndNewlines)

        if profilesWithAddress.isEmpty && currentUserAddress.isEmpty {
            isLoading = false
            return
        }

        for profile in profilesWithAddress {
            let trimmed = profile.address.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let coordinate = await geocode(trimmed) else { continue }
            pins.append(ProfileMapPin(id: profile.id, profile: profile, coordinate: coordinate, isCurrentUser: false))
        }

        // Add current user pin by the address on their profile (not GPS).
        if !currentUserAddress.isEmpty, let coordinate = await geocode(currentUserAddress) {
            pins.append(ProfileMapPin(
                id: currentUser.id,
                profile: currentUser,
                coordinate: coordinate,
                isCurrentUser: true
            ))
        }

        isLoading = false
    }

    private func geocode(_ address: String) async -> CLLocationCoordinate2D? {
        guard let request = MKGeocodingRequest(addressString: address) else { return nil }
        return await withCheckedContinuation { continuation in
            request.getMapItems { mapItems, _ in
                continuation.resume(returning: mapItems?.first?.location.coordinate)
            }
        }
    }
}

struct FindMapView: View {
    let profiles: [UserProfile]
    let currentUser: UserProfile
    let languageCode: String
    let onSelect: (UserProfile) -> Void

    @StateObject private var geocoder = FindMapGeocoder()
    @State private var position: MapCameraPosition = .automatic

    private func t(_ key: VikaL10n.Key) -> String {
        VikaL10n.t(key, languageCode: languageCode)
    }

    private var profilesWithAddress: Bool {
        profiles.contains { !$0.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } || !currentUser.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var profileListSignature: String {
        let ids = profiles.map(\.id).sorted().joined(separator: "|")
        let myAddr = currentUser.address.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(ids)|\(currentUser.id)|\(myAddr)"
    }

    var body: some View {
        Group {
            if !profilesWithAddress {
                ContentUnavailableView(
                    t(.findMapNoAddresses),
                    systemImage: "mappin.slash",
                    description: Text(t(.findTryChangeFilter))
                )
            } else if geocoder.isLoading && geocoder.pins.isEmpty {
                ProgressView(t(.findMapLoading))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if geocoder.pins.isEmpty {
                ContentUnavailableView(
                    t(.findNoResults),
                    systemImage: "map",
                    description: Text(t(.findMapNoAddresses))
                )
            } else {
                Map(position: $position) {
                    ForEach(geocoder.pins) { pin in
                        Annotation(pin.profile.fullName, coordinate: pin.coordinate) {
                            if pin.isCurrentUser {
                                // Display only; don't open user details.
                                Image(systemName: "location.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 38, height: 38)
                                    .background(Color.appGreen.opacity(0.95), in: Circle())
                                    .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
                                    .accessibilityLabel("You")
                            } else {
                                Button {
                                    onSelect(pin.profile)
                                } label: {
                                    Image(systemName: roleSymbol(for: pin.profile.role))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Color.appGreen, in: Circle())
                                        .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(pin.profile.fullName)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .flat))
                .onChange(of: geocoder.pins.count) { _, _ in
                    position = Self.cameraPosition(for: geocoder.pins)
                }
            }
        }
        .task(id: profileListSignature) {
            await geocoder.load(profiles: profiles, currentUser: currentUser)
            if !geocoder.pins.isEmpty {
                position = Self.cameraPosition(for: geocoder.pins)
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

    private static func cameraPosition(for pins: [ProfileMapPin]) -> MapCameraPosition {
        guard !pins.isEmpty else { return .automatic }
        let coords = pins.map(\.coordinate)
        let minLat = coords.map(\.latitude).min()!
        let maxLat = coords.map(\.latitude).max()!
        let minLon = coords.map(\.longitude).min()!
        let maxLon = coords.map(\.longitude).max()!

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let latDelta = max((maxLat - minLat) * 1.35, 0.05)
        let lonDelta = max((maxLon - minLon) * 1.35, 0.05)
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
        return .region(region)
    }
}
