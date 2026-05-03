//
//  AuthService.swift
//  Vika
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

/// Entries for saving the profile photo gallery (max 5 items in the UI).
enum GalleryProfileEntry {
    case keepRemoteURL(String)
    case uploadNew(Data)
}

struct AuthService {
    private let auth = Auth.auth()
    private let usersRef = Database.database().reference().child("users")
    private let storageRef = Storage.storage().reference().child("profileImages")

    func createUser(
        firstName: String,
        lastName: String,
        phoneNumber: String,
        email: String,
        password: String,
        role: UserRole = .user
    ) async throws -> String {
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            auth.createUser(withEmail: email, password: password) { authResult, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let uid = authResult?.user.uid else {
                    continuation.resume(throwing: NSError(domain: "AuthService", code: -1))
                    return
                }

                continuation.resume(returning: uid)
            }
        }

        let payload: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "phoneNumber": phoneNumber,
            "email": email,
            "address": "",
            "showPhoneNumber": false,
            "showAddress": false,
            "isFolder": false,
            "chargingFee": 0,
            "profileImageURL": "",
            "galleryImageURLs": [] as [String],
            "role": role.rawValue,
            "createdAt": ServerValue.timestamp(),
            "updatedAt": ServerValue.timestamp(),
            "lastLoginAt": ServerValue.timestamp()
        ]

        try await setValue(payload, at: usersRef.child(result))
        return result
    }

    func signIn(email: String, password: String) async throws -> String {
        let uid = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            auth.signIn(withEmail: email, password: password) { authResult, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let uid = authResult?.user.uid else {
                    continuation.resume(throwing: NSError(domain: "AuthService", code: -2))
                    return
                }

                continuation.resume(returning: uid)
            }
        }

        try await updateLastLogin(for: uid)
        return uid
    }

    func sendPasswordReset(email: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            auth.sendPasswordReset(withEmail: email) { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: ())
            }
        }
    }

    func fetchUserProfile(uid: String) async throws -> UserProfile {
        let snapshot = try await getData(at: usersRef.child(uid))
        guard let value = snapshot.value as? [String: Any] else {
            throw NSError(domain: "AuthService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Profile not found."])
        }
        return try parseUserProfile(uid: uid, value: value)
    }

    func fetchProfiles(for role: UserRole) async throws -> [UserProfile] {
        let snapshot = try await getData(at: usersRef)
        guard let value = snapshot.value as? [String: [String: Any]] else {
            return []
        }

        return try value.compactMap { uid, payload in
            let profile = try parseUserProfile(uid: uid, value: payload)
            return profile.role == role ? profile : nil
        }
    }

    func updateUserProfile(
        uid: String,
        firstName: String,
        lastName: String,
        phoneNumber: String,
        address: String,
        showPhoneNumber: Bool,
        showAddress: Bool,
        isFolder: Bool,
        chargingFee: Double,
        profileImageData: Data?,
        galleryEntries: [GalleryProfileEntry],
        previouslySavedGalleryURLs: [String]
    ) async throws -> (profileImageURL: String?, galleryURLs: [String]) {
        var payload: [AnyHashable: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "phoneNumber": phoneNumber,
            "address": address,
            "showPhoneNumber": showPhoneNumber,
            "showAddress": showAddress,
            "isFolder": isFolder,
            "chargingFee": chargingFee,
            "updatedAt": ServerValue.timestamp()
        ]
        if isFolder {
            payload["role"] = UserRole.folder.rawValue
        }
        var uploadedImageURL: String?

        if let profileImageData {
            let downloadURL = try await uploadProfileImage(uid: uid, imageData: profileImageData)
            payload["profileImageURL"] = downloadURL
            uploadedImageURL = downloadURL
        }

        var finalGalleryURLs: [String] = []
        for entry in galleryEntries {
            switch entry {
            case .keepRemoteURL(let url):
                finalGalleryURLs.append(url)
            case .uploadNew(let data):
                let downloadURL = try await uploadGalleryImage(uid: uid, imageData: data)
                finalGalleryURLs.append(downloadURL)
            }
        }

        payload["galleryImageURLs"] = finalGalleryURLs

        try await updateChildValues(payload, at: usersRef.child(uid))

        let removedURLs = Set(previouslySavedGalleryURLs).subtracting(Set(finalGalleryURLs))
        for url in removedURLs {
            await deleteStorageFileIfPossible(at: url)
        }

        return (uploadedImageURL, finalGalleryURLs)
    }

    /// Persists which folder profiles the current user marked as favorites (`users/{currentUserId}/favoriteFolderIds/{folderUserId}`).
    func setFolderFavorite(currentUserId: String, folderUserId: String, isFavorite: Bool) async throws {
        let ref = usersRef.child(currentUserId).child("favoriteFolderIds").child(folderUserId)
        if isFavorite {
            try await setValue(true, at: ref)
        } else {
            try await removeValue(at: ref)
        }
    }

    private func updateLastLogin(for uid: String) async throws {
        try await updateChildValues(
            [
                "lastLoginAt": ServerValue.timestamp(),
                "updatedAt": ServerValue.timestamp()
            ],
            at: usersRef.child(uid)
        )
    }

    private func setValue(_ value: Any, at ref: DatabaseReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.setValue(value) { error, _ in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func removeValue(at ref: DatabaseReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.removeValue { error, _ in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func updateChildValues(_ values: [AnyHashable: Any], at ref: DatabaseReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.updateChildValues(values) { error, _ in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func getData(at ref: DatabaseReference) async throws -> DataSnapshot {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DataSnapshot, Error>) in
            ref.getData { error, snapshot in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let snapshot else {
                    continuation.resume(throwing: NSError(domain: "AuthService", code: -4))
                    return
                }

                continuation.resume(returning: snapshot)
            }
        }
    }

    private func parseUserProfile(uid: String, value: [String: Any]) throws -> UserProfile {
        guard let profile = UserProfile(id: uid, dictionary: value) else {
            throw NSError(domain: "AuthService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Profile is malformed."])
        }
        return profile
    }

    private func uploadProfileImage(uid: String, imageData: Data) async throws -> String {
        let ref = storageRef.child("\(uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StorageMetadata, Error>) in
            ref.putData(imageData, metadata: metadata) { metadata, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: metadata ?? StorageMetadata())
            }
        }

        let url = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            ref.downloadURL { url, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let url else {
                    continuation.resume(throwing: NSError(domain: "AuthService", code: -6))
                    return
                }
                continuation.resume(returning: url)
            }
        }

        return url.absoluteString
    }

    private func uploadGalleryImage(uid: String, imageData: Data) async throws -> String {
        let fileName = UUID().uuidString + ".jpg"
        let ref = storageRef.child("\(uid)/gallery/\(fileName)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StorageMetadata, Error>) in
            ref.putData(imageData, metadata: metadata) { metadata, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: metadata ?? StorageMetadata())
            }
        }

        let url = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            ref.downloadURL { url, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let url else {
                    continuation.resume(throwing: NSError(domain: "AuthService", code: -7))
                    return
                }
                continuation.resume(returning: url)
            }
        }

        return url.absoluteString
    }

    private func deleteStorageFileIfPossible(at urlString: String) async {
        guard URL(string: urlString) != nil else { return }
        do {
            let ref = Storage.storage().reference(forURL: urlString)
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                ref.delete { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
        } catch {
            // Orphaned files are acceptable if rules deny delete or URL is external.
        }
    }
}
