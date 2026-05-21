# Verification Context — Edge Case Scenarios

## Purpose

Define testable edge case scenarios in Given/When/Then format to verify the implementation handles boundary conditions, error states, and non-functional requirements.
This document serves as the single source of truth for edge case verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "cart-ec1-empty", "user-ec2-locked"). No two scenarios should share mutable state.

## Edge Case Scenarios:

---

### EC 1: Pre-Login — Network & Session Failures

- [ ] **Scenario: App launches with no network connectivity before login**
  - Given: Device `device-ec1-offline` has no network access and `hasCompletedOnboarding = false` in AppStorage
  - When: The app launches and `RootNavigationCoordinator.deriveAppState()` is called
  - Then: `appState` is set to `.welcome`, `WelcomeView` is rendered without crashing, and no network-dependent state derivation is attempted
  - Verify: `RootNavigationCoordinator.appState == .welcome`; app does not hang or show an error screen; `WelcomeView` is fully interactive

- [ ] **Scenario: App launches with an expired or invalid session token**
  - Given: User `user-ec1-expired-session` has `hasCompletedOnboarding = true` in AppStorage but Supabase session token is expired
  - When: `AuthViewModel` evaluates `isLoggedIn` on app start and the session refresh fails
  - Then: `isLoggedIn` resolves to `false`, `RootNavigationCoordinator` derives `appState = .unauthenticated`, and `LoginOrSignUpScreen` is rendered
  - Verify: `appState == .unauthenticated`; no authenticated view leaks; expired token is not treated as valid; transition animation completes within 500ms

- [ ] **Scenario: Auth state observable emits an error during coordinator observation**
  - Given: `RootNavigationCoordinator` for `user-ec1-auth-error` is actively observing `authViewModel.$isLoggedIn` via Combine
  - When: The Combine publisher emits a completion event or the subscription is deallocated unexpectedly
  - Then: `appState` retains its last valid value without crashing; the coordinator does not enter an undefined state
  - Verify: `appState` is one of `.welcome`, `.unauthenticated`, or `.authenticated`; no force-unwrap crash; subscription cancellables are released cleanly in `deinit`

---

### EC 2: Pre-Login — Invalid Credentials & Boundary Inputs

- [ ] **Scenario: Login attempt with empty credentials**
  - Given: `LoginOrSignUpScreen` is displayed for `user-ec2-empty-creds` with `appState == .unauthenticated`
  - When: The user submits the login form with empty email and empty password fields
  - Then: `AuthViewModel` returns a validation error; `isLoggedIn` remains `false`; `RootNavigationCoordinator.appState` stays `.unauthenticated`
  - Verify: `appState` does not transition to `.authenticated`; error feedback is presented in `LoginOrSignUpScreen`; no state mutation occurs on the coordinator

- [ ] **Scenario: Login attempt with maximum-length invalid credentials**
  - Given: `LoginOrSignUpScreen` is active for `user-ec2-maxlen` and the user enters an email of 255 characters and a password of 128 characters, both invalid
  - When: The form is submitted
  - Then: `AuthViewModel` processes the request and returns an authentication failure; `isLoggedIn` stays `false`; `appState` remains `.unauthenticated`
  - Verify: App does not crash processing oversized input; `appState == .unauthenticated`; UI recovers to allow a retry

---

### EC 3: Post-Login — Session Loss & State Inconsistency

- [ ] **Scenario: Session is invalidated remotely while user is authenticated**
  - Given: User `user-ec3-remote-revoke` has `appState == .authenticated(userId: "user-ec3-remote-revoke")` and is on `HomeView`
  - When: The Supabase session is revoked server-side and `authViewModel.isLoggedIn` transitions to `false` asynchronously
  - Then: `RootNavigationCoordinator` detects the `isLoggedIn` change via Combine, calls `deriveAppState()`, and sets `appState = .unauthenticated`; `LoginOrSignUpScreen` is rendered with the defined transition animation
  - Verify: `appState == .unauthenticated`; `HomeView` is no longer in the view hierarchy; transition animation is the `authToHome` reverse (`.move(edge: .leading)`) completing within 500ms

- [ ] **Scenario: AppStorage `hasCompletedOnboarding` is reset while user is authenticated**
  - Given: User `user-ec3-storage-reset` has `appState == .authenticated(userId: "user-ec3-storage-reset")` with `hasCompletedOnboarding = true`
  - When: `hasCompletedOnboarding` is externally reset to `false` (e.g., via Settings clear or test teardown)
  - Then: `RootNavigationCoordinator.deriveAppState()` is triggered; since `isLoggedIn` is still `true` but `hasCompletedOnboarding` is `false`, `appState` transitions to `.welcome`
  - Verify: `appState == .welcome`; `WelcomeView` is rendered; authenticated state is not preserved when onboarding flag is invalidated

- [ ] **Scenario: Rapid successive state transitions (welcome → unauthenticated → authenticated) within 500ms**
  - Given: `RootNavigationCoordinator` for `user-ec3-rapid-transition` starts at `appState == .welcome`
  - When: `completeOnboarding()` is called immediately followed by a successful login within 200ms of each other
  - Then: All intermediate states are processed in order; the final `appState` is `.authenticated(userId: "user-ec3-rapid-transition")`; no animation frame is dropped or skipped visibly; each animation completes within its 400ms budget
  - Verify: `appState` sequence is `.welcome` → `.unauthenticated` → `.authenticated`; no duplicate state emissions; UI renders the final authenticated view without flickering

- [ ] **Scenario: `logout()` called when coordinator is already in `.unauthenticated` state**
  - Given: `RootNavigationCoordinator` for `user-ec3-double-logout` has `appState == .unauthenticated`
  - When: `logout()` is invoked a second time (e.g., double-tap or duplicate call)
  - Then: `authViewModel?.logOut()` is called idempotently; `appState` remains `.unauthenticated` without re-triggering animation; no crash or undefined state
  - Verify: `appState == .unauthenticated` before and after; `LoginOrSignUpScreen` does not re-animate; no duplicate `objectWillChange.send()` side effects

---

### EC 4: Post-Login — `userId` Associated Value Boundaries

- [ ] **Scenario: Authenticated state derived with an empty `userId` string**
  - Given: `AuthViewModel` for `user-ec4-empty-userid` reports `isLoggedIn = true` but returns an empty string `""` as the user identifier
  - When: `RootNavigationCoordinator.deriveAppState()` evaluates the user ID
  - Then: The coordinator does not set `appState = .authenticated(userId: "")` with an empty string; it either falls back to `.unauthenticated` or handles the empty ID gracefully per the guarding logic
  - Verify: `appState` is `.unauthenticated` or a safely guarded `.authenticated` value; the empty user ID is not propagated into the view hierarchy

---

### EC 5: No Onboarding Access — Incomplete or Corrupted State

- [ ] **Scenario: `hasCompletedOnboarding` is `false` with a valid cached session**
  - Given: User `user-ec5-no-onboard` has `hasCompletedOnboarding = false` in AppStorage but `AuthViewModel` has a valid cached session with `isLoggedIn = true`
  - When: The app launches and `RootNavigationCoordinator.deriveAppState()` runs
  - Then: `appState` is set to `.welcome` because onboarding takes precedence over auth state; `WelcomeView` is rendered regardless of the valid session
  - Verify: `appState == .welcome`; `HomeView` is not rendered; `WelcomeView` is shown so the user can complete onboarding; auth session is preserved in `AuthViewModel` for reuse after onboarding

- [ ] **Scenario: Onboarding screen is dismissed without completing `completeOnboarding()`**
  - Given: User `user-ec5-incomplete-onboard` is on `WelcomeView` with `appState == .welcome` and navigates through `OnboardingContainerView` but the flow is interrupted (e.g., app backgrounded and foregrounded)
  - When: The app returns to foreground and `hasCompletedOnboarding` is still `false`
  - Then: `appState` remains `.welcome`; `WelcomeView` is re-rendered; onboarding progress is not corrupted; user can restart onboarding
  - Verify: `appState == .welcome`; `hasCompletedOnboarding == false` in AppStorage; no partial state is written to AppStorage; coordinator re-derives state correctly on foreground

- [ ] **Scenario: AppStorage value for `hasCompletedOnboarding` is corrupted or non-boolean**
  - Given: The AppStorage entry for key `"hasCompletedOnboarding"` for `device-ec5-corrupted` holds an unexpected value type (e.g., `nil` or a non-boolean due to storage corruption)
  - When: `RootNavigationCoordinator` reads `@AppStorage("hasCompletedOnboarding")` during initialization
  - Then: The `@AppStorage` default value of `false` is applied; `appState` defaults to `.welcome`; no crash occurs from type mismatch
  - Verify: `appState == .welcome`; `WelcomeView` is rendered as a safe default; app does not crash on corrupted UserDefaults entry

---

### EC 6: Animation Performance Boundary

- [ ] **Scenario: State transition animation exceeds 500ms threshold**
  - Given: Device `device-ec6-slow` is under CPU-heavy load and `appState` is `.unauthenticated`
  - When: A successful login triggers `appState` to transition to `.authenticated(userId: "user-ec6-perf")` and the `authToHome` animation (`.move(edge: .trailing).combined(with: .opacity)`) begins
  - Then: The animation is driven by the SwiftUI animation system and completes within 500ms regardless of device load; the `.easeInOut(duration: 0.4)` timing ensures the total transition does not exceed the 400ms budget plus render overhead
  - Verify: Animation duration is configured to ≤ 400ms (`defaultDuration = 0.4`); no jank or skipped frames are observable; `HomeView` is fully rendered and interactive after transition completes

- [ ] **Scenario: `RootNavigationAnimations.animationFor` called with an undefined transition tuple**
  - Given: `RootNavigationAnimations.animationFor(transition:)` is invoked with a transition not explicitly mapped (e.g., `.welcome` → `.authenticated` skipping `.unauthenticated`)
  - When: The pattern match in `animationFor` finds no matching case
  - Then: The fallback animation `.easeInOut(duration: 0.4)` is returned; the transition still completes smoothly without crashing
  - Verify: No `fatalError` or crash; a valid `Animation` value is always returned; transition completes visually within 500ms

---

### EC 7: Coordinator Lifecycle & Memory Safety

- [ ] **Scenario: `RootNavigationCoordinator` is deallocated while a state update is in-flight**
  - Given: `RootNavigationCoordinator` for `user-ec7-dealloc` is mid-transition with a Combine subscription active
  - When: The coordinator is deallocated (e.g., parent view removed) before the async state update on `DispatchQueue.main` completes
  - Then: The weak reference pattern and cancellables cleanup in `deinit` prevent a dangling reference; no `EXC_BAD_ACCESS` crash occurs
  - Verify: `cancellables` are cleared in `deinit`; any queued `DispatchQueue.main` closures referencing `[weak self]` safely no-op; no memory leak is reported by Instruments

- [ ] **Scenario: Multiple `completeOnboarding()` calls in rapid succession**
  - Given: `RootNavigationCoordinator` for `user-ec7-rapid-onboard` has `appState == .welcome` and `hasCompletedOnboarding = false`
  - When: `completeOnboarding()` is called three times within 100ms (e.g., triple-tap or test race condition)
  - Then: `hasCompletedOnboarding` is set to `true` on the first call; subsequent calls are idempotent; `deriveAppState()` emits at most one meaningful state change; `appState` transitions to `.unauthenticated` exactly once
  - Verify: `appState == .unauthenticated` after all calls; no duplicate animation triggers; `objectWillChange.send()` is not called redundantly if state did not change
