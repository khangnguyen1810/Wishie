import SwiftUI
import Combine

class RootNavigationCoordinator: ObservableObject {
    @Published var appState: AppState = .welcome
    private let authViewModel: AuthViewModel
    private var cancellables = Set<AnyCancellable>()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        self.appState = deriveAppState(isLoggedIn: authViewModel.isLoggedIn)

        authViewModel.$isLoggedIn
            .sink { [weak self] isLoggedIn in
                guard let self else { return }
                let newState = self.deriveAppState(isLoggedIn: isLoggedIn)
                if self.appState != newState {
                    self.appState = newState
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .map { _ in UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateAppState()
            }
            .store(in: &cancellables)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        updateAppState()
    }

    func logout() {
        authViewModel.logOut()
        updateAppState()
    }

    private func updateAppState() {
        let newState = deriveAppState(isLoggedIn: authViewModel.isLoggedIn)
        if appState != newState {
            appState = newState
        }
    }

    private func deriveAppState(isLoggedIn: Bool) -> AppState {
        if !hasCompletedOnboarding {
            return .welcome
        }

        if isLoggedIn,
           let userId = UserDefaults.standard.string(forKey: "userid"),
           !userId.isEmpty {
            return .authenticated(userId: userId)
        }

        return .unauthenticated
    }
}
