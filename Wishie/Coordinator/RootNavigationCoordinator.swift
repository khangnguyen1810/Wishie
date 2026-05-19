import SwiftUI
import Combine

class RootNavigationCoordinator: ObservableObject {
    @Published var appState: AppState = .welcome
    private let authViewModel: AuthViewModel
    private var cancellables = Set<AnyCancellable>()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        self.appState = deriveAppState()

        authViewModel.$isLoggedIn
            .sink { [weak self] _ in
                self?.appState = self?.deriveAppState() ?? .welcome
            }
            .store(in: &cancellables)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        appState = deriveAppState()
    }

    func logout() {
        authViewModel.logOut()
        appState = deriveAppState()
    }

    private func deriveAppState() -> AppState {
        if !hasCompletedOnboarding {
            return .welcome
        }

        if authViewModel.isLoggedIn,
           let userId = UserDefaults.standard.string(forKey: "userid"),
           !userId.isEmpty {
            return .authenticated(userId: userId)
        }

        return .unauthenticated
    }
}
