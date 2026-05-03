//
//  LoginView.swift
//  Vika
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    enum AuthMode: String, CaseIterable, Identifiable {
        case signIn = "Sign In"
        case signUp = "Sign Up"

        var id: String { rawValue }
    }

    let onAuthenticated: (UserProfile) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("selectedLanguage") private var selectedLanguageCode = "en"
    @State private var mode: AuthMode = .signIn

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var isSubmitting = false
    @State private var alertMessage: String?

    private func t(_ key: VikaL10n.Key) -> String {
        VikaL10n.t(key, languageCode: selectedLanguageCode)
    }

    var body: some View {
        ZStack {
            Image(colorScheme == .dark ? "ColorsDark" : "Colors")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    header
                    modeSwitch
                    formSection
                    submitButton
                    footer
                }
                .padding(.horizontal, 16)
                .padding(.top, 44)
                .padding(.bottom, 24)
            }
        }
        .alert(mode == .signIn ? t(.loginAlertTitle) : t(.accountAlertTitle), isPresented: alertIsPresented) {
            Button(t(.alertOK), role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "basket.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.appGreen)

            Text("Vika")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.primary)

            Text(t(.appTagline))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 50)
    }

    private var modeSwitch: some View {
        HStack(spacing: 0) {
            modeButton(.signIn)
            modeButton(.signUp)
        }
        .padding(3)
        .background(Color.white.opacity(0.35), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func modeButton(_ modeValue: AuthMode) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                mode = modeValue
            }
        } label: {
            Text(modeValue == .signIn ? t(.loginSignIn) : t(.loginSignUp))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    Group {
                        if mode == modeValue {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.95))
                        } else {
                            Color.clear
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if mode == .signUp {
                fieldTitle(t(.loginFullName))
                fieldBackground {
                    TextField(t(.loginEnterFullName), text: $fullName)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
            }

            fieldTitle(t(.loginEmail))
            fieldBackground {
                TextField(t(.loginEnterEmail), text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            fieldTitle(t(.loginPassword))
            fieldBackground {
                secureField(
                    placeholder: t(.loginEnterPassword),
                    text: $password,
                    isVisible: $isPasswordVisible,
                    contentType: mode == .signIn ? .password : .newPassword
                )
            }

            if mode == .signUp {
                fieldTitle(t(.loginConfirmPassword))
                fieldBackground {
                    secureField(
                        placeholder: t(.loginConfirmYourPassword),
                        text: $confirmPassword,
                        isVisible: $isConfirmPasswordVisible,
                        contentType: .password
                    )
                }
            }
        }
    }

    private func fieldTitle(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.top, 4)
    }

    private func fieldBackground<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.32))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.gray.opacity(0.35), lineWidth: 1)
            )
    }

    private func secureField(
        placeholder: String,
        text: Binding<String>,
        isVisible: Binding<Bool>,
        contentType: UITextContentType?
    ) -> some View {
        HStack(spacing: 10) {
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

            Spacer(minLength: 0)

            Button {
                isVisible.wrappedValue.toggle()
            } label: {
                Image(systemName: "eye.fill")
                    .font(.body)
                    .foregroundStyle(.gray)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
    }

    private var submitButton: some View {
        Button(action: submitTapped) {
            if isSubmitting {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            } else {
                Text(mode == .signIn ? t(.loginSignIn) : t(.loginSignUp))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
        }
        .buttonStyle(.plain)
        .background(Color.appGreen, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .disabled(isSubmitting)
        .padding(.top, 10)
    }

    private var footer: some View {
        VStack(spacing: 14) {
            if mode == .signIn {
                Button(t(.loginForgotPassword)) {
                    forgotPasswordTapped()
                }
                .font(.body)
                .foregroundStyle(Color.appGreen)
                .buttonStyle(.plain)
            }

            HStack(spacing: 6) {
                Text(mode == .signIn ? t(.loginDontHaveAccount) : t(.loginAlreadyHaveAccount))
                    .font(.body)
                    .foregroundStyle(.secondary)

                Button(mode == .signIn ? t(.loginSignUp) : t(.loginSignIn)) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        mode = mode == .signIn ? .signUp : .signIn
                    }
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.appGreen)
                .buttonStyle(.plain)
            }
        }
    }

    private var alertIsPresented: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )
    }

    private func submitTapped() {
        mode == .signIn ? signInTapped() : signUpTapped()
    }

    private func signInTapped() {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanedEmail.isEmpty, !password.isEmpty else {
            alertMessage = t(.loginPleaseEnterEmailAndPassword)
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
                    alertMessage = authErrorMessage(for: error, context: .signIn)
                }
            }
        }
    }

    private func signUpTapped() {
        let cleanedFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let names = splitFullName(cleanedFullName)

        guard !cleanedFullName.isEmpty, !cleanedEmail.isEmpty, !password.isEmpty else {
            alertMessage = t(.loginPleaseFillAllFields)
            return
        }

        guard password == confirmPassword else {
            alertMessage = t(.loginPasswordsDoNotMatch)
            return
        }

        isSubmitting = true

        Task {
            do {
                let authService = AuthService()
                let uid = try await authService.createUser(
                    firstName: names.firstName,
                    lastName: names.lastName,
                    phoneNumber: "",
                    email: cleanedEmail,
                    password: password
                )
                let profile = try await authService.fetchUserProfile(uid: uid)
                await MainActor.run {
                    isSubmitting = false
                    onAuthenticated(profile)
                }
            } catch let error as NSError {
                await MainActor.run {
                    isSubmitting = false
                    alertMessage = authErrorMessage(for: error, context: .signUp)
                }
            }
        }
    }

    private enum AuthErrorContext {
        case signIn
        case signUp
    }

    private func authErrorMessage(for error: NSError, context: AuthErrorContext) -> String {
        if let authCode = AuthErrorCode(rawValue: error.code) {
            switch authCode {
            case .wrongPassword, .invalidCredential:
                return t(.loginIncorrectCredentials)
            case .userNotFound:
                return t(.loginNoAccountFound)
            case .invalidEmail:
                return t(.loginInvalidEmail)
            case .emailAlreadyInUse:
                return t(.loginEmailInUse)
            case .weakPassword:
                return t(.loginChooseStrongerPassword)
            default:
                return error.localizedDescription
            }
        }

        return context == .signUp ? t(.loginCreateFailed) : error.localizedDescription
    }

    private func forgotPasswordTapped() {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanedEmail.isEmpty else {
            alertMessage = t(.loginEnterEmailFirst)
            return
        }

        Task {
            do {
                try await AuthService().sendPasswordReset(email: cleanedEmail)
                await MainActor.run {
                    alertMessage = t(.loginResetEmailSent)
                }
            } catch let error as NSError {
                await MainActor.run {
                    alertMessage = authErrorMessage(for: error, context: .signIn)
                }
            }
        }
    }

    private func splitFullName(_ value: String) -> (firstName: String, lastName: String) {
        let parts = value.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard let first = parts.first else { return ("", "") }
        let last = parts.dropFirst().joined(separator: " ")
        return (first, last)
    }
}

#Preview {
    LoginView(onAuthenticated: { _ in })
}
