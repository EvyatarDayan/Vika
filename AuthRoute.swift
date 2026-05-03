//
//  AuthRoute.swift
//  Vika
//

import Foundation

enum AuthRoute: Hashable {
    case signIn(UserRole)
    case signUp(UserRole)
}
