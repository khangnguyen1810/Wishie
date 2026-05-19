//
//  WishieApp.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 5/10/25.
//

import SwiftUI
import Combine
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        return true
    }
}

@main
struct WishieApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var coordinator: RootNavigationCoordinator
    @State private var isActive: Bool = false

    init() {
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
        }
    }
}
