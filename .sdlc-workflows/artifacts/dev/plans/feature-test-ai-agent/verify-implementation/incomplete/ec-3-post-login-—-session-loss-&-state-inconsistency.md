# EC 3: Post-Login — Session Loss & State Inconsistency

- [x] **Scenario: Session is invalidated remotely while user is authenticated**
  - Given: User `user-ec3-remote-revoke` has `appState == .authenticated(userId: "user-ec3-remote-revoke")` and is on `HomeView`
  - When: The Supabase session is revoked server-side and `authViewModel.isLoggedIn` transitions to `false` asynchronously
  - Then: `RootNavigationCoordinator` detects the `isLoggedIn` change via Combine, calls `deriveAppState()`, and sets `appState = .unauthenticated`; `LoginOrSignUpScreen` is rendered with the defined transition animation
  - Verify: `appState == .unauthenticated`; `HomeView` is no longer in the view hierarchy; transition animation is the `authToHome` reverse (`.move(edge: .leading)`) completing within 500ms

- [ ] **Scenario: AppStorage `hasCompletedOnboarding` is reset while user is authenticated** ❌ FAILED
  - Given: User `user-ec3-storage-reset` has `appState == .authenticated(userId: "user-ec3-storage-reset")` with `hasCompletedOnboarding = true`
  - When: `hasCompletedOnboarding` is externally reset to `false` (e.g., via Settings clear or test teardown)
  - Then: `RootNavigationCoordinator.deriveAppState()` is triggered; since `isLoggedIn` is still `true` but `hasCompletedOnboarding` is `false`, `appState` transitions to `.welcome`
  - Verify: `appState == .welcome`; `WelcomeView` is rendered; authenticated state is not preserved when onboarding flag is invalidated
  - **Failure**: `appState` remains `.authenticated` after external reset of `hasCompletedOnboarding`; `WelcomeView` is never rendered
  - **Root Cause**: `RootNavigationCoordinator` only subscribes to `authViewModel.$isLoggedIn` via Combine (lines 14–18 in `RootNavigationCoordinator.swift`). The `@AppStorage("hasCompletedOnboarding")` property in an `ObservableObject` class does **not** automatically call `objectWillChange` or invoke `deriveAppState()` when UserDefaults changes externally. There is no `NotificationCenter` observer, no additional Combine publisher, and no KVO hook wired to call `deriveAppState()` on `hasCompletedOnboarding` changes.
  - **Affected Files**: [Wishie/Coordinator/RootNavigationCoordinator.swift](Wishie/Coordinator/RootNavigationCoordinator.swift) — `init` (lines 10–19) is missing observation of `hasCompletedOnboarding`

- [x] **Scenario: Rapid successive state transitions (welcome → unauthenticated → authenticated) within 500ms**
  - Given: `RootNavigationCoordinator` for `user-ec3-rapid-transition` starts at `appState == .welcome`
  - When: `completeOnboarding()` is called immediately followed by a successful login within 200ms of each other
  - Then: All intermediate states are processed in order; the final `appState` is `.authenticated(userId: "user-ec3-rapid-transition")`; no animation frame is dropped or skipped visibly; each animation completes within its 400ms budget
  - Verify: `appState` sequence is `.welcome` → `.unauthenticated` → `.authenticated`; no duplicate state emissions; UI renders the final authenticated view without flickering

- [ ] **Scenario: `logout()` called when coordinator is already in `.unauthenticated` state** ❌ FAILED
  - Given: `RootNavigationCoordinator` for `user-ec3-double-logout` has `appState == .unauthenticated`
  - When: `logout()` is invoked a second time (e.g., double-tap or duplicate call)
  - Then: `authViewModel?.logOut()` is called idempotently; `appState` remains `.unauthenticated` without re-triggering animation; no crash or undefined state
  - Verify: `appState == .unauthenticated` before and after; `LoginOrSignUpScreen` does not re-animate; no duplicate `objectWillChange.send()` side effects
  - **Failure**: Two redundant `objectWillChange` emissions occur per `logout()` call when already `.unauthenticated`
  - **Root Cause**: `logout()` (lines 26–29) calls `authViewModel.logOut()`, which synchronously sets `isLoggedIn = false` (already `false`). Because `@Published` emits for every assignment—not only when the value changes—the `authViewModel.$isLoggedIn` Combine sink fires immediately, setting `appState = .unauthenticated` (first `objectWillChange`). Control then returns to `logout()`, which calls `appState = deriveAppState()` → `.unauthenticated` again (second `objectWillChange`). The design has the Combine sink and the direct assignment in `logout()` both responsible for writing `appState`, causing the double-fire on every `logout()` invocation.
  - **Affected Files**: [Wishie/Coordinator/RootNavigationCoordinator.swift](Wishie/Coordinator/RootNavigationCoordinator.swift) — `logout()` (lines 26–29) and the `$isLoggedIn` sink (lines 14–18)

---
