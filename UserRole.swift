//
//  UserRole.swift
//  Vika
//

import Foundation

enum UserRole: String, CaseIterable, Identifiable, Hashable, Sendable {
    case user
    case folder
    case client

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .user: "User"
        case .folder: "As a Folder"
        case .client: "As a Client"
        }
    }

    var shortDescription: String {
        switch self {
        case .user: "Vika account"
        case .folder: "I can help fold laundry."
        case .client: "I need help folding my laundry."
        }
    }
}
