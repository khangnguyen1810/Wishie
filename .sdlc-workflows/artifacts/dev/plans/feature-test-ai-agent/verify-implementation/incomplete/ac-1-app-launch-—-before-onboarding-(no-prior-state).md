# AC 1: App Launch — Before Onboarding (No Prior State)

- [x] **Scenario: Fresh install shows WelcomeView when onboarding has not been completed**
  - Given: A device with no prior app data, `hasCompletedOnboarding` is `false`, and `authViewModel-ac1-fresh.isLoggedIn` is `false`
  - When: The app launches and the LaunchScreen finishes its display cycle in `WishieApp.swift`
  - Then: `RootNavigationCoordinator` derives `appState = .welcome` and `MainView` renders `WelcomeView`
  - Verify: `appState` equals `.welcome`; `WelcomeView` is the active root view; no `LoginOrSignUpScreen` or `HomeView` is visible

- [x] **Scenario: RootNavigationCoordinator initializes with .welcome as the default state**
  - Given: A `RootNavigationCoordinator` instance initialized with `authViewModel-ac1-coordinator` where `isLoggedIn = false` and `hasCompletedOnboarding = false`
  - When: The coordinator's `init(authViewModel:)` completes and `deriveAppState()` is called
  - Then: `appState` is set to `.welcome` without any further user interaction
  - Verify: `coordinator.appState == .welcome`; no state derivation errors; initial state is stable

---
