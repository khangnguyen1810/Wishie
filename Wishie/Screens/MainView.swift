//
//  RootView.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 16/3/26.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var rootNavigationCoordinator: RootNavigationCoordinator
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        switch rootNavigationCoordinator.appState {
        case .welcome:
            WelcomeView()
                .transition(.opacity)
        case .unauthenticated:
            LoginOrSignUpScreen()
                .transition(.move(edge: .leading))
        case .authenticated:
            HomeView()
                .environmentObject(authViewModel)
                .transition(.move(edge: .trailing))
        }
    }
}
