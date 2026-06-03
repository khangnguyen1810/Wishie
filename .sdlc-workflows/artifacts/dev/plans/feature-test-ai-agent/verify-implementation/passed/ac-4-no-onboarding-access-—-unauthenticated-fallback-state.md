# AC 4: No Onboarding Access — Unauthenticated Fallback State

- [x] **Scenario: User without active session lands on LoginOrSignUpScreen after onboarding is complete**
  - Given: User `user-ac4-noauth` has `hasCompletedOnboarding = true` but no active session (`authViewModel-ac4-noauth.isLoggedIn = false`)
  - When: The app launches and `RootNavigationCoordinator` derives state
  - Then: `appState = .unauthenticated` and `LoginOrSignUpScreen` is rendered; user is not redirected to `WelcomeView` or `HomeView`
  - Verify: `coordinator.appState == .unauthenticated`; correct screen is shown without intermediate flickers; `WelcomeView` is not shown

- [x] **Scenario: Coordinator remains .unauthenticated when login fails, with no state regression to .welcome**
  - Given: User `user-ac4-fail` has `hasCompletedOnboarding = true` and is on `LoginOrSignUpScreen` (`appState-ac4-fail = .unauthenticated`)
  - When: The user submits invalid credentials and `authViewModel-ac4-fail.isLoggedIn` remains `false`
  - Then: `RootNavigationCoordinator` does not alter `appState`; it remains `.unauthenticated`; the user stays on `LoginOrSignUpScreen`
  - Verify: `coordinator.appState == .unauthenticated`; no navigation to `.welcome` or `.authenticated`; error feedback is provided to the user via `AuthViewModel`

- [x] **Scenario: Coordinator is injectable as EnvironmentObject for access throughout the view hierarchy**
  - Given: `RootNavigationCoordinator` instance `coordinator-ac4-env` is created in `WishieApp.swift` and passed as an `@EnvironmentObject` to `MainView`
  - When: A nested view in the hierarchy (e.g., within `HomeView`) reads the coordinator from the environment
  - Then: The coordinator instance is accessible and its `appState` reflects the current navigation state without requiring direct initialization
  - Verify: `@EnvironmentObject var coordinator: RootNavigationCoordinator` resolves without a fatal error; `coordinator.appState` returns the correct current state

---

