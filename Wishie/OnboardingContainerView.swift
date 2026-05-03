//
//  OnboardingView1.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 5/10/25.
//

import SwiftUI

struct Onboarding: Identifiable {
    var id: UUID = UUID()
    var image: String
    var headline: String
    
}
let onboardings: [Onboarding] = [
    Onboarding(image: "onboardingImg1", headline: "Create your personal wishlist"),
    Onboarding(image: "onboardingImg2", headline: "Share with Family & Friends"),
    Onboarding(image: "onboardingImg3", headline: "Get the gift you truly want"),
]
struct OnboardingView: View {
    @State private var currentIndex = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                // Hiển thị nội dung theo trang
                let onboarding = onboardings[currentIndex]
                
                Text(onboarding.headline)
                    .foregroundStyle(Color.white)
                    .font(.wishies(.bold, 50))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Nút Next / Continue
                if currentIndex == onboardings.count - 1 {
                    NavigationLink(destination: ContentUnavailableView("Main view", systemImage: "house")) {
                        customButton(title: "Continue")
                    }
                } else {
                    Button {
                        withAnimation {
                            currentIndex += 1
                        }
                    } label: {
                        customButton(title: "Next")
                    }
                }
                
                Spacer()
            }
            .safeAreaPadding(.bottom, 60)
            .safeAreaPadding(.top, 120)
            .padding(.horizontal, 30)
            .background(
                ZStack {
                    Image(onboardings[currentIndex].image)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    LinearGradient(
                        gradient: Gradient(colors: [.darkGrey.opacity(0.5), .black.opacity(0.8)]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                }
            )
            .navigationBarBackButtonHidden()
        }
    }
    
    // MARK: - Reusable Button
    @ViewBuilder
    func customButton(title: String) -> some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(.lightYellow)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .overlay(
                Text(title)
                    .font(.wishies(.bold, 20))
                    .foregroundStyle(.black)
            )
    }
}

struct OnboardingContainer: View {
    @State private var currentIndex = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $currentIndex) {
                ForEach(Array(onboardings.enumerated()), id: \.offset) { index, item in
                    OnboardingView()
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
}

#Preview {
    OnboardingContainer()
}
