//
//  OnboardingView1.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 5/10/25.
//

import SwiftUI

struct Onboarding: Identifiable {
    var id: UUID = UUID()
    let image: String
    let headline: String
    
}
let onboardings: [Onboarding] = [
    Onboarding(image: "onboardingImg1", headline: "Create your personal wishlist"),
    Onboarding(image: "onboardingImg2", headline: "Share with Family & Friends"),
    Onboarding(image: "onboardingImg3", headline: "Get the gift you truly want"),
]
struct OnboardingView: View {
    var onboarding: Onboarding
    @Binding var currentIndex: Int
    @EnvironmentObject var coordinator: RootNavigationCoordinator
    @State var headlineContent: String = ""
    @State private var amount = -10.0
    @State var nextPage: Bool = false
    var body: some View {
        onboadingViewContent(image: onboarding.image, headline: onboarding.headline)
            .navigationBarBackButtonHidden()
    }
    @ViewBuilder
    func onboadingViewContent(image: String, headline: String) -> some View {
        VStack {
            if currentIndex == 2 {
                Spacer()
            }
            Text(headlineContent)
                .foregroundStyle(Color.white)
                .font(.wishies(.bold, 50))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, currentIndex == 2 ? 40 : 0)
                .task {
                    await typeWriter()
                }
                .onChange(of: currentIndex) { _, _ in
                    Task {
                        headlineContent = ""
                        await typeWriter()
                    }
                }
            if currentIndex != 2 {
                Spacer()
            }
            if currentIndex == onboardings.count - 1 {
                Button {
                    coordinator.completeOnboarding()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.lightYellow)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                        Text("Continue")
                            .font(.wishies(.bold, 20))
                            .foregroundStyle(.black)
                    }
                }
            } else {
                Button {
                    currentIndex += 1
                    nextPage = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.lightYellow)
                            .frame(width: .infinity, height: 60)
                        Text("Next")
                            .font(.wishies(.bold, 20))
                            .foregroundStyle(.black)
                    }
                }
                
            }
        }
        .safeAreaPadding(.bottom,60)
        .safeAreaPadding(.top,80)
        .padding(.horizontal,30)
        .background {
            Image(image)
                .resizable()
                .frame(maxHeight: .infinity)
                .aspectRatio(contentMode: .fill)
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.darkGrey.opacity(0.5), .black.opacity(0.8)]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .ignoresSafeArea()
        }
    }
    func typeWriter() async {
        if nextPage {
            headlineContent = ""
        }
        for char in onboarding.headline {
            headlineContent.append(char)
            try? await Task.sleep(for: .milliseconds(75))
        }
    }
}
struct OnboardingContainerView: View {
    @State private var currentIndex = 0
    @State private var startTyping = true
    var body: some View {
        OnboardingView(onboarding: onboardings[currentIndex], currentIndex: $currentIndex)
    }
}
#Preview {
    let authViewModel = AuthViewModel()
    OnboardingContainerView()
        .environmentObject(RootNavigationCoordinator(authViewModel: authViewModel))
}
