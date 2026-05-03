//
//  WishieApp.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 5/10/25.
//

import SwiftUI
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
    @State private var isActive: Bool = false
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isActive {
                   MainView()
                        .environmentObject(authViewModel)
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring) {
                        isActive = true
                    }
                }
            }
        }
    }
}
