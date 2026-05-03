//
//  RootView.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 16/3/26.
//

import SwiftUI
struct MainView: View {

    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {

        if !hasCompletedOnboarding {
            WelcomeView()
                .transition(.opacity)

        } else if authViewModel.isLoggedIn {
            HomeView()
                .transition(.move(edge: .trailing))

        } else {
            LoginOrSignUpScreen()
                .transition(.move(edge: .leading))
        }
    }
}
