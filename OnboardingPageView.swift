//
//  OnboardingPageView.swift
//  Vika
//

import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            Image(systemName: page.systemImage)
                .font(.system(size: 80))
                .foregroundStyle(Color.appGreen)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.title2)
                    .foregroundStyle(Color.appGreen)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }
            .padding(.top, 30)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    OnboardingPageView(
        page: OnboardingPage(
            title: "Welcome to Vika",
            subtitle: "Laundry help, made simple",
            systemImage: "basket.fill",
            description: "Vika connects busy families who need folding help with local Folders who can take a pile off your hands."
        )
    )
}
