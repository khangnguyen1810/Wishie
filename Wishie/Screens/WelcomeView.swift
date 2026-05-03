//
//  WelcomeScreen.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 5/10/25.
//

import SwiftUI

struct WelcomeView: View {

    var body: some View {
        NavigationStack {
            ZStack {
                Image("welcomeviewimg")
                    .resizable()
                    .frame(
                        maxWidth: .infinity,
                        maxHeight:.infinity,
                        alignment: .center
                    )
                LinearGradient(gradient: Gradient(colors: [.darkGrey.opacity(0.5), .black.opacity(0.8)]), startPoint: .bottom, endPoint: .top)
                VStack {
                    Text("Welcome to \nWishie")
                        .foregroundStyle(Color.white)
                        .font(.wishies(.bold, 50))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    NavigationLink(destination: OnboardingContainerView()) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.lightYellow)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                            Text("Let's get started")
                                .font(.wishies(.bold, 20))
                                .foregroundStyle(.black)
                        }
                    }
                }
                .safeAreaPadding(.bottom,60)
                .safeAreaPadding(.top,120)
                .padding(.horizontal,30)
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    WelcomeView()
}
