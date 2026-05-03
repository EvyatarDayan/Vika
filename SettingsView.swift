//
//  SettingsView.swift
//  Vika
//

import SwiftUI

struct BottomRoundedRectangle: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()

        return path
    }
}

struct SettingsView: View {
    let currentUser: UserProfile
    let onLogout: () -> Void
    let onProfileUpdated: (UserProfile) -> Void

    @AppStorage("selectedLanguage") private var selectedLanguageCode = "en"
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var profileForSettings: UserProfile

    @State private var showingProfileSheet = false
    @State private var showingLanguagePicker = false
    @State private var showingCurrencyPicker = false
    @State private var showingExportAlert = false
    @State private var exportAlertMessage = ""
    @State private var showingClearDataAlert = false
    @State private var showingHelpSupport = false
    @State private var showingTermsPrivacy = false
    @State private var showingAbout = false

    private var language: Language {
        Language.language(forCode: selectedLanguageCode)
    }

    private func t(_ key: VikaL10n.Key) -> String {
        VikaL10n.t(key, languageCode: selectedLanguageCode)
    }

    init(
        currentUser: UserProfile,
        onLogout: @escaping () -> Void,
        onProfileUpdated: @escaping (UserProfile) -> Void = { _ in }
    ) {
        self.currentUser = currentUser
        self.onLogout = onLogout
        self.onProfileUpdated = onProfileUpdated
        _profileForSettings = State(initialValue: currentUser)
    }

    var body: some View {
        Form {
            Section {
                EmptyView()
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section(t(.settingsAuthentication)) {
                Button {
                    showingProfileSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(profileForSettings.fullName)
                                .font(.body)
                                .foregroundColor(.primary)

                            Text(profileForSettings.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            Section(t(.settingsPreferences)) {
                Button {
                    showingLanguagePicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(t(.settingsLanguage))
                                .font(.body)
                                .foregroundColor(.primary)

                            Text(t(.settingsLanguageSubtitle))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Text(language.flag)
                                .font(.title2)

                            Text(language.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Button {
                    showingCurrencyPicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.appGreen)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(t(.settingsCurrency))
                                .font(.body)
                                .foregroundColor(.primary)

                            Text(t(.settingsCurrencyTapToChoose))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        CurrencyCodeFlagLabel(flagFont: .title2, codeFont: .subheadline.weight(.semibold))

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(t(.settingsCurrency)), \(LocaleCurrency.iso4217Code)")

                HStack(spacing: 12) {
                    Image(systemName: "moon.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(t(.settingsDarkMode))
                            .font(.body)
                            .foregroundColor(.primary)

                        Text(t(.settingsDarkModeSubtitle))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }

                    Spacer()

                    CompactSwitchControl(
                        isOn: $isDarkMode,
                        accessibilityLabelText: t(.settingsDarkMode)
                    )
                }
            }

            Section(t(.settingsSupport)) {
                Button {
                    showingHelpSupport = true
                } label: {
                    SettingsRow(
                        icon: "questionmark.circle.fill",
                        iconColor: .blue,
                        title: t(.settingsHelpSupport),
                        subtitle: t(.settingsHelpSupportSubtitle)
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Button {
                    showingTermsPrivacy = true
                } label: {
                    SettingsRow(
                        icon: "lock.shield.fill",
                        iconColor: .green,
                        title: t(.settingsTermsPrivacy),
                        subtitle: t(.settingsTermsPrivacySubtitle)
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Button {
                    showingAbout = true
                } label: {
                    SettingsRow(
                        icon: "info.circle.fill",
                        iconColor: .blue,
                        title: t(.settingsAbout),
                        subtitle: t(.settingsAboutSubtitle)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }

            Section(t(.settingsDataManagement)) {
                Button {
                    exportAlertMessage = t(.settingsExportComingSoon)
                    showingExportAlert = true
                } label: {
                    SettingsRow(
                        icon: "square.and.arrow.up.fill",
                        iconColor: .blue,
                        title: t(.settingsExportData),
                        subtitle: t(.settingsExportDataSubtitle)
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Button {
                    showingClearDataAlert = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "trash.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(t(.settingsClearAllData))
                                .font(.body)
                                .foregroundColor(.red)

                            Text(t(.settingsClearAllDataSubtitle))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }

            Section {
                Text("")
                    .frame(height: 30)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
        }
        .navigationTitle(t(.settingsTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onLogout) {
                    Text(t(.settingsLogout))
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
                }
            }
        }
        .sheet(isPresented: $showingLanguagePicker) {
            LanguageSelectionModal()
        }
        .sheet(isPresented: $showingCurrencyPicker) {
            SelectCurrencyView()
        }
        .sheet(isPresented: $showingProfileSheet) {
            NavigationStack {
                ProfileView(profile: profileForSettings) { updatedProfile in
                    profileForSettings = updatedProfile
                    onProfileUpdated(updatedProfile)
                    showingProfileSheet = false
                }
            }
        }
        .onChange(of: currentUser) { _, newValue in
            profileForSettings = newValue
        }
        .sheet(isPresented: $showingHelpSupport) {
            SettingsInfoSheet(title: t(.settingsHelpSupport), bodyText: t(.settingsHelpSupportSubtitle))
        }
        .sheet(isPresented: $showingTermsPrivacy) {
            SettingsInfoSheet(title: t(.settingsTermsPrivacy), bodyText: t(.settingsTermsPrivacySubtitle))
        }
        .sheet(isPresented: $showingAbout) {
            SettingsInfoSheet(title: t(.settingsAbout), bodyText: "Vika")
        }
        .alert(t(.settingsExportAlertTitle), isPresented: $showingExportAlert) {
            Button(t(.alertOK)) { }
        } message: {
            Text(exportAlertMessage)
        }
        .alert(t(.settingsClearAlertTitle), isPresented: $showingClearDataAlert) {
            Button(t(.settingsCancel), role: .cancel) { }
            Button(t(.settingsClearAll), role: .destructive) { }
        } message: {
            Text(t(.settingsClearAlertMessage))
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct SettingsInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedLanguage") private var selectedLanguageCode = "en"
    let title: String
    let bodyText: String

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(bodyText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(VikaL10n.t(.settingsDone, languageCode: selectedLanguageCode)) { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            currentUser: UserProfile(
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
            onLogout: {},
            onProfileUpdated: { _ in }
        )
    }
}
