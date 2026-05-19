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
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @State private var rootNavigationCoordinator: RootNavigationCoordinator?
    @State private var isActive: Bool = false

    var body: some Scene {
        WindowGroup {
            let coordinator = rootNavigationCoordinator ?? RootNavigationCoordinator(authViewModel: authViewModel)

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
            .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
            .onAppear {
                if rootNavigationCoordinator == nil {
                    rootNavigationCoordinator = RootNavigationCoordinator(authViewModel: authViewModel)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring) {
                        isActive = true
                    }
                }
            }
        }
    }
}
