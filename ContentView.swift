//
//  ContentView.swift
//  Vika
//
//  Created by EVYATAR DAYAN on 2026-03-22.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentUser: UserProfile?
    @State private var isRestoringSession = true

    var body: some View {
        Group {
            if isRestoringSession {
                ProgressView()
            } else if let currentUser {
                FindView(currentUser: currentUser) {
                    try? Auth.auth().signOut()
                    self.currentUser = nil
                }
            } else if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                LoginView(onAuthenticated: { profile in
                    currentUser = profile
                })
            }
        }
        .task {
            guard isRestoringSession else { return }

            defer { isRestoringSession = false }
            guard let uid = Auth.auth().currentUser?.uid else { return }

            do {
                currentUser = try await AuthService().fetchUserProfile(uid: uid)
            } catch {
                try? Auth.auth().signOut()
                currentUser = nil
            }
        }
    }
}

#Preview {
    ContentView()
}
