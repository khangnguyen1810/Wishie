# EC 1: Pre-Login — Network & Session Failures

- [x] **Scenario: App launches with no network connectivity before login**
  - Given: Device `device-ec1-offline` has no network access and `hasCompletedOnboarding = false` in AppStorage
  - When: The app launches and `RootNavigationCoordinator.deriveAppState()` is called
  - Then: `appState` is set to `.welcome`, `WelcomeView` is rendered without crashing, and no network-dependent state derivation is attempted
  - Verify: `RootNavigationCoordinator.appState == .welcome`; app does not hang or show an error screen; `WelcomeView` is fully interactive

- [ ] **Scenario: App launches with an expired or invalid session token** ❌ FAILED
  - Given: User `user-ec1-expired-session` has `hasCompletedOnboarding = true` in AppStorage but Supabase session token is expired
  - When: `AuthViewModel` evaluates `isLoggedIn` on app start and the session refresh fails
  - Then: `isLoggedIn` resolves to `false`, `RootNavigationCoordinator` derives `appState = .unauthenticated`, and `LoginOrSignUpScreen` is rendered
  - Verify: `appState == .unauthenticated`; no authenticated view leaks; expired token is not treated as valid; transition animation completes within 500ms
  - **Failure**: The scenario expects `isLoggedIn = false` after a failed session refresh, but `checkToken()` does not perform any token validation against Firebase — it only checks for the presence of a non-empty `"userid"` string in `UserDefaults`. An expired or revoked token stored in `UserDefaults` is indistinguishable from a valid one, so `isLoggedIn` is set to `true` and `deriveAppState()` returns `.authenticated(userId:)`, rendering `HomeView` instead of `LoginOrSignUpScreen`.
  - **Root Cause**: `AuthViewModel.checkToken()` uses purely local `UserDefaults` presence as the validity signal with no backend session validation or Firebase token refresh. There is no mechanism to detect that a stored UID corresponds to an expired or invalid session.
  - **Affected Files**: [Wishie/Screens/Auth/AuthViewModel.swift](Wishie/Screens/Auth/AuthViewModel.swift) — `checkToken()` method (lines 32–35); [Wishie/Coordinator/RootNavigationCoordinator.swift](Wishie/Coordinator/RootNavigationCoordinator.swift) — `deriveAppState()` method (lines 31–43)

- [x] **Scenario: Auth state observable emits an error during coordinator observation**
  - Given: `RootNavigationCoordinator` for `user-ec1-auth-error` is actively observing `authViewModel.$isLoggedIn` via Combine
  - When: The Combine publisher emits a completion event or the subscription is deallocated unexpectedly
  - Then: `appState` retains its last valid value without crashing; the coordinator does not enter an undefined state
  - Verify: `appState` is one of `.welcome`, `.unauthenticated`, or `.authenticated`; no force-unwrap crash; subscription cancellables are released cleanly in `deinit`

---
