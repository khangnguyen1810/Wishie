//
//  OnboardingView1.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 5/10/25.
//

import SwiftUI

struct Onboarding: Identifiable {
    var id: UUID = UUID()
    let image: String
    let headline: String
    let subtext: String
}
let onboardings: [Onboarding] = [
    Onboarding(
        image: "ob-image-1",
        headline: "Create your personal wishlist",
        subtext: "Drop a link, a photo or a note — it lands in your wishlist in one tap."
    ),
    Onboarding(
        image: "ob-image-2",
        headline: "Share with Family & Friends",
        subtext: "Send one link to friends and family. They see exactly what you want."
    ),
    Onboarding(
        image: "ob-image-3",
        headline: "Get the gift you truly want",
        subtext: "Reserved items get marked, so nobody buys the same thing twice."
    ),
]
struct OnboardingView: View {
    var onboarding: Onboarding
    @Binding var currentIndex: Int
    @EnvironmentObject var coordinator: RootNavigationCoordinator
    @State private var contentVisible: Bool = false

    var body: some View {
        onboardingViewContent(image: onboarding.image, headline: onboarding.headline, subtext: onboarding.subtext)
            .navigationBarBackButtonHidden()
    }

    @ViewBuilder
    func onboardingViewContent(image: String, headline: String, subtext: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    coordinator.completeOnboarding()
                } label: {
                    Text("Skip")
                        .font(.wishies(.medium, 16))
                        .foregroundStyle(Color("obInk"))
                }
            }

            Spacer()

            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: currentIndex == 1 ? 282 : 268)
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 12)

            Text(headline)
                .font(.wishiesDisplay(.bold, 32))
                .foregroundStyle(Color("obInk"))
                .multilineTextAlignment(.center)
                .padding(.top, 32)
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 12)

            Text(subtext)
                .font(.wishies(.regular, 16))
                .foregroundStyle(Color("obInk").opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 12)

            Spacer()

            PaginationDotsView(count: onboardings.count, currentIndex: currentIndex)
                .padding(.bottom, 24)

            WishieButton(
                title: currentIndex == onboardings.count - 1 ? "Get started" : "Next",
                enabled: true,
                filColor: Color("obInk"),
                titleColor: .white
            ) {
                if currentIndex == onboardings.count - 1 {
                    coordinator.completeOnboarding()
                } else {
                    currentIndex += 1
                }
            }
        }
        .safeAreaPadding(.bottom, 40)
        .safeAreaPadding(.top, 20)
        .padding(.horizontal, 30)
        .background {
            Color("obScreenBg")
                .ignoresSafeArea()
        }
        .task {
            withAnimation(.easeOut(duration: 0.4)) {
                contentVisible = true
            }
        }
        .onChange(of: currentIndex) { _, _ in
            contentVisible = false
            withAnimation(.easeOut(duration: 0.4)) {
                contentVisible = true
            }
        }
    }
}
struct OnboardingContainerView: View {
    @State private var currentIndex = 0
    var body: some View {
        OnboardingView(onboarding: onboardings[currentIndex], currentIndex: $currentIndex)
    }
}
#Preview {
    let authViewModel = AuthViewModel()
    OnboardingContainerView()
        .environmentObject(RootNavigationCoordinator(authViewModel: authViewModel))
}
