//
//  SignInView.swift
//  Vika
//

import SwiftUI
import UIKit
import FirebaseAuth

struct SignInView: View {
    let role: UserRole
    @Binding var path: NavigationPath
    let onAuthenticated: (UserProfile) -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var isSubmitting = false
    @State private var alertMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                labeledField(title: "Email") {
                    TextField("Email address", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }

                VStack(alignment: .leading, spacing: 10) {
                    fieldTitle("Password")

                    passwordRow
                        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                    Button(action: forgotPasswordTapped) {
                        Text("Forgot password?")
                            .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color(uiColor: .link))
                    .padding(.top, 2)
                }

                Button(action: loginTapped) {
                    if isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Text("Login")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.appGreen)
                .padding(.top, 4)
                .disabled(isSubmitting)

                signUpFooter
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Log in")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Login", isPresented: alertIsPresented, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(alertMessage ?? "")
        })
    }

    private func fieldTitle(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
    }

    private func labeledField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldTitle(title)
            content()
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var passwordRow: some View {
        HStack(spacing: 12) {
            Group {
                if isPasswordVisible {
                    TextField("Password", text: $password)
                } else {
                    SecureField("Password", text: $password)
                }
            }
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                    .foregroundStyle(.secondary)
                    .font(.body)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 10)
    }

    private var signUpFooter: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            Text("Don't have an account? ")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Sign up") {
                path.append(AuthRoute.signUp(role))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color(uiColor: .link))
            Spacer(minLength: 0)
        }
        .multilineTextAlignment(.center)
        .padding(.top, 8)
    }

    private var alertIsPresented: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { isVisible in
                if !isVisible {
                    alertMessage = nil
                }
            }
        )
    }

    private func loginTapped() {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanedEmail.isEmpty, !password.isEmpty else {
            alertMessage = "Please enter your email and password."
            return
        }

        isSubmitting = true

        Task {
            do {
                let authService = AuthService()
                let uid = try await authService.signIn(email: cleanedEmail, password: password)
                let profile = try await authService.fetchUserProfile(uid: uid)
                await MainActor.run {
                    isSubmitting = false
                    onAuthenticated(profile)
                }
            } catch let error as NSError {
                await MainActor.run {
                    isSubmitting = false
                    alertMessage = userMessage(for: error)
                }
            }
        }
    }

    private func forgotPasswordTapped() {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanedEmail.isEmpty else {
            alertMessage = "Enter your email first, then tap Forgot password."
            return
        }

        Task {
            do {
                try await AuthService().sendPasswordReset(email: cleanedEmail)
                await MainActor.run {
                    alertMessage = "Reset email sent."
                }
            } catch let error as NSError {
                await MainActor.run {
                    alertMessage = userMessage(for: error)
                }
            }
        }
    }

    private func userMessage(for error: NSError) -> String {
        if let authCode = AuthErrorCode(rawValue: error.code) {
            switch authCode {
            case .wrongPassword, .invalidCredential:
                return "Email or password is incorrect."
            case .userNotFound:
                return "No account found for this email."
            case .invalidEmail:
                return "Please enter a valid email address."
            default:
                return error.localizedDescription
            }
        }

        return error.localizedDescription
    }
}

#Preview {
    NavigationStack {
        SignInView(role: .folder, path: .constant(NavigationPath()), onAuthenticated: { _ in })
    }
}
