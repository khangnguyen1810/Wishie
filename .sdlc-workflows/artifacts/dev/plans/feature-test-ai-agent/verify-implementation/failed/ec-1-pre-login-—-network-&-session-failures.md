# EC 1: Pre-Login — Network & Session Failures

- [x] **Scenario: App launches with no network connectivity before login**
  - Given: Device `device-ec1-offline` has no network access and `hasCompletedOnboarding = false` in AppStorage
  - When: The app launches and `RootNavigationCoordinator.deriveAppState()` is called
  - Then: `appState` is set to `.welcome`, `WelcomeView` is rendered without crashing, and no network-dependent state derivation is attempted
  - Verify: `RootNavigationCoordinator.appState == .welcome`; app does not hang or show an error screen; `WelcomeView` is fully interactive

- [x] **Scenario: App launches with an expired or invalid session token** ✅ RESOLVED
  - Given: User `user-ec1-expired-session` has `hasCompletedOnboarding = true` in AppStorage but Supabase session token is expired
  - When: `AuthViewModel` evaluates `isLoggedIn` on app start and the session refresh fails
  - Then: `isLoggedIn` resolves to `false`, `RootNavigationCoordinator` derives `appState = .unauthenticated`, and `LoginOrSignUpScreen` is rendered
  - Verify: `appState == .unauthenticated`; no authenticated view leaks; expired token is not treated as valid; transition animation completes within 500ms
  - **Resolution**: Replaced the purely local `UserDefaults` presence check in `AuthViewModel.checkToken()` with Firebase-backed session validation. The method now (1) checks `Auth.auth().currentUser` — returning nil for any expired or revoked Firebase session — and verifies it matches the stored `userid`; (2) calls `getIDToken(forcingRefresh: true)` to force a network round-trip that confirms server-side token validity; (3) only sets `isLoggedIn = true` on a successful refresh, and clears `UserDefaults` on any error, ensuring `deriveAppState()` returns `.unauthenticated` for expired sessions. The `RootNavigationCoordinator`'s existing Combine subscription on `$isLoggedIn` propagates the async result without further changes.
  - **Affected Files**: [Wishie/Screens/Auth/AuthViewModel.swift](Wishie/Screens/Auth/AuthViewModel.swift) — `checkToken()` method

- [x] **Scenario: Auth state observable emits an error during coordinator observation**
  - Given: `RootNavigationCoordinator` for `user-ec1-auth-error` is actively observing `authViewModel.$isLoggedIn` via Combine
  - When: The Combine publisher emits a completion event or the subscription is deallocated unexpectedly
  - Then: `appState` retains its last valid value without crashing; the coordinator does not enter an undefined state
  - Verify: `appState` is one of `.welcome`, `.unauthenticated`, or `.authenticated`; no force-unwrap crash; subscription cancellables are released cleanly in `deinit`

---
