# EC 3: Post-Login — Session Loss & State Inconsistency

- [x] **Scenario: Session is invalidated remotely while user is authenticated**
  - Given: User `user-ec3-remote-revoke` has `appState == .authenticated(userId: "user-ec3-remote-revoke")` and is on `HomeView`
  - When: The Supabase session is revoked server-side and `authViewModel.isLoggedIn` transitions to `false` asynchronously
  - Then: `RootNavigationCoordinator` detects the `isLoggedIn` change via Combine, calls `deriveAppState()`, and sets `appState = .unauthenticated`; `LoginOrSignUpScreen` is rendered with the defined transition animation
  - Verify: `appState == .unauthenticated`; `HomeView` is no longer in the view hierarchy; transition animation is the `authToHome` reverse (`.move(edge: .leading)`) completing within 500ms

- [x] **Scenario: AppStorage `hasCompletedOnboarding` is reset while user is authenticated** ✅ RESOLVED
  - Given: User `user-ec3-storage-reset` has `appState == .authenticated(userId: "user-ec3-storage-reset")` with `hasCompletedOnboarding = true`
  - When: `hasCompletedOnboarding` is externally reset to `false` (e.g., via Settings clear or test teardown)
  - Then: `RootNavigationCoordinator.deriveAppState()` is triggered; since `isLoggedIn` is still `true` but `hasCompletedOnboarding` is `false`, `appState` transitions to `.welcome`
  - Verify: `appState == .welcome`; `WelcomeView` is rendered; authenticated state is not preserved when onboarding flag is invalidated
  - **Resolution**: Added a `NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)` Combine subscription in `init`. It maps to the current `hasCompletedOnboarding` value, applies `.removeDuplicates()`, and calls `updateAppState()` on change. This ensures `deriveAppState()` is re-evaluated whenever `hasCompletedOnboarding` is mutated externally, correctly transitioning `appState` to `.welcome`.
  - **Affected Files**: [Wishie/Coordinator/RootNavigationCoordinator.swift](Wishie/Coordinator/RootNavigationCoordinator.swift) — added `NotificationCenter` publisher in `init`

- [x] **Scenario: Rapid successive state transitions (welcome → unauthenticated → authenticated) within 500ms**
  - Given: `RootNavigationCoordinator` for `user-ec3-rapid-transition` starts at `appState == .welcome`
  - When: `completeOnboarding()` is called immediately followed by a successful login within 200ms of each other
  - Then: All intermediate states are processed in order; the final `appState` is `.authenticated(userId: "user-ec3-rapid-transition")`; no animation frame is dropped or skipped visibly; each animation completes within its 400ms budget
  - Verify: `appState` sequence is `.welcome` → `.unauthenticated` → `.authenticated`; no duplicate state emissions; UI renders the final authenticated view without flickering

- [x] **Scenario: `logout()` called when coordinator is already in `.unauthenticated` state** ✅ RESOLVED
  - Given: `RootNavigationCoordinator` for `user-ec3-double-logout` has `appState == .unauthenticated`
  - When: `logout()` is invoked a second time (e.g., double-tap or duplicate call)
  - Then: `authViewModel?.logOut()` is called idempotently; `appState` remains `.unauthenticated` without re-triggering animation; no crash or undefined state
  - Verify: `appState == .unauthenticated` before and after; `LoginOrSignUpScreen` does not re-animate; no duplicate `objectWillChange.send()` side effects
  - **Resolution**: Introduced `updateAppState()` private helper that calls `deriveAppState()` and only assigns to `appState` when the new value differs (equality guard using `AppState`'s `Hashable`/`Equatable` conformance). All call sites — the `$isLoggedIn` sink, `completeOnboarding()`, and `logout()` — now route through `updateAppState()`. When `logout()` is called while already `.unauthenticated`, both the sink and the direct call derive `.unauthenticated`, the equality guard blocks the assignment, and no `objectWillChange` is emitted.
  - **Affected Files**: [Wishie/Coordinator/RootNavigationCoordinator.swift](Wishie/Coordinator/RootNavigationCoordinator.swift) — added `updateAppState()` helper; updated `logout()`, `completeOnboarding()`, and `$isLoggedIn` sink to use it

---

