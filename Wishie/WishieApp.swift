//
//  WishieApp.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 5/10/25.
//

import SwiftUI
import Combine
import Firebase
import GoogleSignIn

@main
struct WishieApp: App {
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var coordinator: RootNavigationCoordinator
    @State private var isActive: Bool = false

    init() {
        if FirebaseApp.app() == nil {

            FirebaseApp.configure()

        }
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        let auth = AuthViewModel()
        _authViewModel = StateObject(wrappedValue: auth)
        _coordinator = StateObject(wrappedValue: RootNavigationCoordinator(authViewModel: auth))
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isActive {
                    MainView()
                        .environmentObject(authViewModel)
                        .environmentObject(coordinator)
                } else {
                    Image("LaunchScreen")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                }
            }
            .preferredColorScheme(.light)
            .animation(.easeInOut(duration: 0.4), value: authViewModel.isLoggedIn)
            .animation(RootNavigationAnimations.welcomeToAuth, value: coordinator.appState)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring) {
                        isActive = true
                    }
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
