# EC 5: No Onboarding Access — Incomplete or Corrupted State

- [x] **Scenario: `hasCompletedOnboarding` is `false` with a valid cached session**
  - Given: User `user-ec5-no-onboard` has `hasCompletedOnboarding = false` in AppStorage but `AuthViewModel` has a valid cached session with `isLoggedIn = true`
  - When: The app launches and `RootNavigationCoordinator.deriveAppState()` runs
  - Then: `appState` is set to `.welcome` because onboarding takes precedence over auth state; `WelcomeView` is rendered regardless of the valid session
  - Verify: `appState == .welcome`; `HomeView` is not rendered; `WelcomeView` is shown so the user can complete onboarding; auth session is preserved in `AuthViewModel` for reuse after onboarding

- [x] **Scenario: Onboarding screen is dismissed without completing `completeOnboarding()`**
  - Given: User `user-ec5-incomplete-onboard` is on `WelcomeView` with `appState == .welcome` and navigates through `OnboardingContainerView` but the flow is interrupted (e.g., app backgrounded and foregrounded)
  - When: The app returns to foreground and `hasCompletedOnboarding` is still `false`
  - Then: `appState` remains `.welcome`; `WelcomeView` is re-rendered; onboarding progress is not corrupted; user can restart onboarding
  - Verify: `appState == .welcome`; `hasCompletedOnboarding == false` in AppStorage; no partial state is written to AppStorage; coordinator re-derives state correctly on foreground

- [x] **Scenario: AppStorage value for `hasCompletedOnboarding` is corrupted or non-boolean**
  - Given: The AppStorage entry for key `"hasCompletedOnboarding"` for `device-ec5-corrupted` holds an unexpected value type (e.g., `nil` or a non-boolean due to storage corruption)
  - When: `RootNavigationCoordinator` reads `@AppStorage("hasCompletedOnboarding")` during initialization
  - Then: The `@AppStorage` default value of `false` is applied; `appState` defaults to `.welcome`; no crash occurs from type mismatch
  - Verify: `appState == .welcome`; `WelcomeView` is rendered as a safe default; app does not crash on corrupted UserDefaults entry

---

