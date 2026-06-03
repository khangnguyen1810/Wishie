# Task 2: Create RootNavigationCoordinator [ ]

Build the centralized state manager that observes `AuthViewModel` and `AppStorage`, derives unified `AppState`, and provides state update methods.

- 2.1: In `Wishie/Screens/Auth/RootNavigationCoordinator.swift` **CREATE**:
  - Create new file `RootNavigationCoordinator.swift` in [Wishie/Screens/Auth/](Wishie/Screens/Auth/) directory (co-located with AuthViewModel)
  - Define `final class RootNavigationCoordinator: ObservableObject`:
    - Add property `@Published var appState: AppState = .welcome` (default state)
    - Add private property `@ObservedReading(\.isLoggedIn) private var isLoggedInInner: Bool` or use alternative observation pattern
    - Add private `@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false`
    - Add private property `private var authViewModel: AuthViewModel?` to hold weak reference
    - Add private property `private var cancellables = Set<AnyCancellable>()` for Combine subscriptions
  - Implement `init(authViewModel: AuthViewModel)` initializer:
    - Store weak reference to `authViewModel`
    - Set up observation of `authViewModel.$isLoggedIn` to trigger state updates when auth changes
    - Call `deriveAppState()` immediately to set initial state
    - Subscribe to `$hasCompletedOnboarding` changes (AppStorage publishes via ObjectWillChange)
  - Implement private method `private func deriveAppState()`:
    - If `hasCompletedOnboarding` is false, set `appState = .welcome`
    - Else if `isLoggedIn` is true and user ID can be retrieved, set `appState = .authenticated(userId: /* from AuthViewModel or UserDefaults */)`
    - Else set `appState = .unauthenticated`
    - Call `objectWillChange.send()` to trigger published update
  - Implement public method `func completeOnboarding()`:
    - Set `hasCompletedOnboarding = true`
    - Call `deriveAppState()` to update published state
  - Implement public method `func logout()`:
    - Call `authViewModel?.logOut()` (AuthViewModel already handles UserDefaults cleanup)
    - Set `appState = .unauthenticated`

- 2.2: In `Wishie/Screens/Auth/RootNavigationCoordinator.swift` **ADD** (continuation):
  - Add deinit to clean up Combine cancellables
  - Ensure thread safety for state derivation (use DispatchQueue.main for state updates if needed)
  - Add documentation comment describing coordinator's role as single source of truth for root navigation

---

