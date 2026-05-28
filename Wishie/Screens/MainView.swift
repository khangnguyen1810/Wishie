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
    @State private var currentAnimation: Animation = RootNavigationAnimations.welcomeToAuth

    var body: some View {
        ZStack {
            switch rootNavigationCoordinator.appState {
            case .welcome:
                WelcomeView()
                    .transition(.opacity)
            case .unauthenticated:
                LoginOrSignUpScreen()
                    .transition(.opacity)
            case .interestsSetup:
                InterestsSelectionView()
                    .environmentObject(authViewModel)
                    .transition(.opacity)
            case .authenticated:
                HomeView()
                    .environmentObject(authViewModel)
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(currentAnimation, value: rootNavigationCoordinator.appState)
        .onChange(of: rootNavigationCoordinator.appState) { oldState, newState in
            currentAnimation = RootNavigationAnimations.animationFor(transition: (from: oldState, to: newState))
        }
    }
}
