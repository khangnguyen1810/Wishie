//
//  LoginOrSignUpScreen.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 7/10/25.
//

import SwiftUI

struct LoginOrSignUpScreen: View {
    @State private var path = NavigationPath()
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                stage
                copy
                    .padding(.top, 24)
                Spacer(minLength: 16)
                actions
                    .layoutPriority(1)
            }
            .safeAreaPadding(.bottom, 40)
            .background {
                Color("obScreenBg")
                    .ignoresSafeArea()
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .navigationDestination(for: String.self) { path in
                switch(path) {
                case "login":
                    LoginView()
                        .environmentObject(authViewModel)
                        .navigationBarBackButtonHidden()
                case "signup":
                    SignUpView()
                        .environmentObject(authViewModel)
                        .navigationBarBackButtonHidden()
                default:
                    ContentUnavailableView("Login Screen", systemImage: "person.fill")
                }
            }
        }
    }

    /// Yellow area holding the fanned sample wishlists. Takes whatever height the copy and actions leave.
    private var stage: some View {
        WishlistFanView()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                UnevenRoundedRectangle(bottomLeadingRadius: 44, bottomTrailingRadius: 44)
                    .fill(Color.lightYellow)
                    .ignoresSafeArea(edges: .top)
            }
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image("pen")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                Text("Wishie")
                    .font(.wishiesDisplay(.bold, 18))
                    .foregroundStyle(Color("obInk"))
            }
            Text("Make a list.\nShare one link.")
                .font(.wishiesDisplay(.bold, 32))
                .foregroundStyle(Color("obInk"))
                .minimumScaleFactor(0.8)
            Text("Friends reserve a gift, so nobody buys the same thing twice.")
                .font(.wishies(.regular, 16))
                .foregroundStyle(Color("obInk").opacity(0.7))
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)
    }

    private var actions: some View {
        VStack(spacing: 6) {
            WishieButton(
                title: "Login",
                enabled: true,
                filColor: Color("obInk"),
                titleColor: .white
            ) {
                path.append("login")
            }
            .accessibilityIdentifier("auth.loginButton")

            Button {
                path.append("signup")
            } label: {
                Text("Don't have an account? \(Text("Sign up").font(.wishies(.bold, 15)).underline())")
                    .font(.wishies(.regular, 15))
                    .foregroundStyle(Color("obInk"))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityIdentifier("auth.signUpLink")
        }
        .padding(.horizontal, 30)
    }
}

#Preview {
    LoginOrSignUpScreen()
        .environmentObject(AuthViewModel())
}
