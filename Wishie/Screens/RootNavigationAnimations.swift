import SwiftUI

enum RootNavigationAnimations {
    static let welcomeToAuth: Animation = .easeInOut(duration: 0.4)
    static let authToHome: Animation = .easeInOut(duration: 0.4)
    static let homeToWelcome: Animation = .easeInOut(duration: 0.4)
    static let defaultDuration: Double = 0.4

    static func animationFor(transition: (from: AppState, to: AppState)) -> Animation {
        switch (transition.from, transition.to) {
        case (.welcome, .unauthenticated):
            return welcomeToAuth
        case (.unauthenticated, .authenticated):
            return authToHome
        case (.unauthenticated, .interestsSetup):
            return authToHome
        case (.interestsSetup, .authenticated):
            return authToHome
        case (.authenticated, .unauthenticated):
            return homeToWelcome
        case (.unauthenticated, .welcome):
            return homeToWelcome
        case (.authenticated, .welcome):
            return homeToWelcome
        default:
            return .easeInOut(duration: defaultDuration)
        }
    }
}
