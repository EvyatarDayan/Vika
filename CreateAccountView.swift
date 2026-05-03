//
//  CreateAccountView.swift
//  Vika
//

import SwiftUI
import UIKit
import FirebaseAuth

struct CreateAccountView: View {
    let role: UserRole
    var onBack: () -> Void

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var isSubmitting = false
    @State private var alertMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                roleChip

                formSection(title: "Personal Information") {
                    formField(placeholder: "First name", text: $firstName, contentType: .givenName, keyboard: .default, nameCapitalization: true)
                    separator
                    formField(placeholder: "Last name", text: $lastName, contentType: .familyName, keyboard: .default, nameCapitalization: true)
                    separator
                    formField(placeholder: "Phone number", text: $phoneNumber, contentType: .telephoneNumber, keyboard: .phonePad, nameCapitalization: false)
                }

                formSection(title: "Email") {
                    formField(placeholder: "Email address", text: $email, contentType: .emailAddress, keyboard: .emailAddress, nameCapitalization: false)
                }

                formSection(title: "Password") {
                    secureRow(placeholder: "Password", text: $password, isVisible: $isPasswordVisible, contentType: .newPassword)
                    separator
                    secureRow(placeholder: "Confirm password", text: $confirmPassword, isVisible: $isConfirmPasswordVisible, contentType: .password)
                }

                Button(action: submitTapped) {
                    if isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Text("Create Account")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
                .disabled(isSubmitting)

                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Text("Already have an account? ")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Login") {
                        onBack()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(uiColor: .link))
                    Spacer(minLength: 0)
                }
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                }
            }
        }
        .alert("Account", isPresented: alertIsPresented, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(alertMessage ?? "")
        })
    }

    private var roleChip: some View {
        HStack(spacing: 8) {
            Image(systemName: role == .folder ? "basket.fill" : "house.fill")
                .font(.subheadline)
            Text(role.displayTitle)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground), in: Capsule())
    }

    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                content()
            }
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var separator: some View {
        Divider()
            .padding(.leading, 16)
    }

    private func formField(
        placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType?,
        keyboard: UIKeyboardType,
        nameCapitalization: Bool
    ) -> some View {
        TextField(placeholder, text: text)
            .textContentType(contentType)
            .keyboardType(keyboard)
            .textInputAutocapitalization(nameCapitalization ? .words : .never)
            .autocorrectionDisabled(!nameCapitalization)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .foregroundStyle(.primary)
    }

    private func secureRow(placeholder: String, text: Binding<String>, isVisible: Binding<Bool>, contentType: UITextContentType?) -> some View {
        HStack(spacing: 12) {
            Group {
                if isVisible.wrappedValue {
                    TextField(placeholder, text: text)
                } else {
                    SecureField(placeholder, text: text)
                }
            }
            .textContentType(contentType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isVisible.wrappedValue.toggle()
            } label: {
                Image(systemName: isVisible.wrappedValue ? "eye" : "eye.slash")
                    .foregroundStyle(.secondary)
                    .font(.body)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isVisible.wrappedValue ? "Hide password" : "Show password")
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 10)
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

    private func submitTapped() {
        guard !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty else {
            alertMessage = "Please fill out all fields."
            return
        }

        guard password == confirmPassword else {
            alertMessage = "Passwords do not match."
            return
        }

        isSubmitting = true
        let cleanedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedPhoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        Task {
            do {
                _ = try await AuthService().createUser(
                    firstName: cleanedFirstName,
                    lastName: cleanedLastName,
                    phoneNumber: cleanedPhoneNumber,
                    email: cleanedEmail,
                    password: password,
                    role: role
                )

                await MainActor.run {
                    isSubmitting = false
                    onBack()
                }
            } catch let error as NSError {
                await MainActor.run {
                    isSubmitting = false
                    alertMessage = userMessage(for: error)
                }
            }
        }
    }

    private func userMessage(for error: NSError) -> String {
        if let authCode = AuthErrorCode(rawValue: error.code) {
            switch authCode {
            case .emailAlreadyInUse:
                return "This email is already in use."
            case .invalidEmail:
                return "Please enter a valid email address."
            case .weakPassword:
                return "Please choose a stronger password."
            default:
                return error.localizedDescription
            }
        }

        return error.localizedDescription
    }
}

#Preview("Create Account — Folder") {
    NavigationStack {
        CreateAccountView(role: .folder, onBack: {})
    }
}
