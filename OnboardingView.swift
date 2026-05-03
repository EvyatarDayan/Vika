//
//  OnboardingView.swift
//  Vika
//

import SwiftUI

struct OnboardingPage {
    let title: String
    let subtitle: String
    let systemImage: String
    let description: String
}

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedLanguage") private var selectedLanguageCode = "en"
    @State private var currentPage = 0

    private var pages: [OnboardingPage] {
        let lang = selectedLanguageCode
        return [
            OnboardingPage(
                title: VikaL10n.t(.onboardingWelcomeTitle, languageCode: lang),
                subtitle: VikaL10n.t(.onboardingWelcomeSubtitle, languageCode: lang),
                systemImage: "basket.fill",
                description: VikaL10n.t(.onboardingWelcomeBody, languageCode: lang)
            ),
            OnboardingPage(
                title: VikaL10n.t(.onboardingClientTitle, languageCode: lang),
                subtitle: VikaL10n.t(.onboardingClientSubtitle, languageCode: lang),
                systemImage: "house.fill",
                description: VikaL10n.t(.onboardingClientBody, languageCode: lang)
            ),
            OnboardingPage(
                title: VikaL10n.t(.onboardingFolderTitle, languageCode: lang),
                subtitle: VikaL10n.t(.onboardingFolderSubtitle, languageCode: lang),
                systemImage: "hands.sparkles.fill",
                description: VikaL10n.t(.onboardingFolderBody, languageCode: lang)
            ),
            OnboardingPage(
                title: VikaL10n.t(.onboardingDoneTitle, languageCode: lang),
                subtitle: VikaL10n.t(.onboardingDoneSubtitle, languageCode: lang),
                systemImage: "checkmark.circle.fill",
                description: VikaL10n.t(.onboardingDoneBody, languageCode: lang)
            )
        ]
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                HStack {
                    if currentPage > 0 {
                        Button(VikaL10n.t(.onboardingPrev, languageCode: selectedLanguageCode)) {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundStyle(Color(uiColor: .link))
                    } else {
                        Spacer()
                    }

                    Spacer()

                    if currentPage < pages.count - 1 {
                        Button(VikaL10n.t(.onboardingNext, languageCode: selectedLanguageCode)) {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.appGreen, in: Capsule())
                    } else {
                        Button(VikaL10n.t(.onboardingGetStarted, languageCode: selectedLanguageCode)) {
                            hasCompletedOnboarding = true
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.appGreen, in: Capsule())
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 24)

                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.appGreen : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.bottom, 32)
            }

            LanguagePickerButton(style: .regular)
                .padding(.trailing, 20)
                .padding(.top, 12)
        }
    }
}

#Preview {
    OnboardingView()
}
