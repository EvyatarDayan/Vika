//
//  UserProfile.swift
//  Vika
//

import Foundation

struct UserProfile: Identifiable, Hashable, Sendable {
    let id: String
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let email: String
    let address: String
    let showPhoneNumber: Bool
    let showAddress: Bool
    let isFolder: Bool
    let chargingFee: Double
    let profileImageURL: String?
    /// Up to 5 extra profile photos (main avatar is `profileImageURL`).
    let galleryImageURLs: [String]
    let role: UserRole
    let createdAt: TimeInterval?
    let updatedAt: TimeInterval?
    let lastLoginAt: TimeInterval?

    var fullName: String {
        let composed = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        return composed.isEmpty ? email : composed
    }

    init(
        id: String,
        firstName: String,
        lastName: String,
        phoneNumber: String,
        email: String,
        address: String,
        showPhoneNumber: Bool = false,
        showAddress: Bool = false,
        isFolder: Bool = false,
        chargingFee: Double = 0,
        profileImageURL: String?,
        galleryImageURLs: [String] = [],
        role: UserRole,
        createdAt: TimeInterval?,
        updatedAt: TimeInterval?,
        lastLoginAt: TimeInterval?
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.email = email
        self.address = address
        self.showPhoneNumber = showPhoneNumber
        self.showAddress = showAddress
        self.isFolder = isFolder
        self.chargingFee = chargingFee
        self.profileImageURL = profileImageURL
        self.galleryImageURLs = galleryImageURLs
        self.role = role
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastLoginAt = lastLoginAt
    }

    init?(
        id: String,
        dictionary: [String: Any]
    ) {
        guard
            let firstName = dictionary["firstName"] as? String,
            let lastName = dictionary["lastName"] as? String,
            let phoneNumber = dictionary["phoneNumber"] as? String,
            let email = dictionary["email"] as? String
        else {
            return nil
        }

        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.email = email
        self.address = dictionary["address"] as? String ?? ""
        self.showPhoneNumber = dictionary["showPhoneNumber"] as? Bool ?? false
        self.showAddress = dictionary["showAddress"] as? Bool ?? false
        self.isFolder = dictionary["isFolder"] as? Bool ?? false
        if let fee = dictionary["chargingFee"] as? Double {
            self.chargingFee = fee
        } else if let fee = dictionary["chargingFee"] as? Int {
            self.chargingFee = Double(fee)
        } else if let fee = dictionary["chargingFee"] as? String, let parsed = Double(fee) {
            self.chargingFee = parsed
        } else {
            self.chargingFee = 0
        }
        self.profileImageURL = dictionary["profileImageURL"] as? String
        if let arr = dictionary["galleryImageURLs"] as? [String] {
            self.galleryImageURLs = arr
        } else if let arr = dictionary["galleryImageURLs"] as? [Any] {
            self.galleryImageURLs = arr.compactMap { $0 as? String }
        } else {
            self.galleryImageURLs = []
        }
        if let roleRaw = dictionary["role"] as? String, let parsedRole = UserRole(rawValue: roleRaw) {
            self.role = parsedRole
        } else {
            self.role = .user
        }
        self.createdAt = dictionary["createdAt"] as? TimeInterval
        self.updatedAt = dictionary["updatedAt"] as? TimeInterval
        self.lastLoginAt = dictionary["lastLoginAt"] as? TimeInterval
    }
}
