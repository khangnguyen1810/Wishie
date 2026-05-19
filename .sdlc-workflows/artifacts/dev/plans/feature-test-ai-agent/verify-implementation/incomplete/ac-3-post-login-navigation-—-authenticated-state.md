# AC 3: Post-Login Navigation — Authenticated State

- [ ] **Scenario: Successful login transitions app state to .authenticated with userId** ❌ FAILED
  - Given: User `user-ac3-login` exists with valid credentials, `appState-ac3-login` is `.unauthenticated`, and `authViewModel-ac3-login.isLoggedIn = false`
  - When: The user submits correct credentials on `LoginOrSignUpScreen` and `authViewModel-ac3-login.isLoggedIn` becomes `true` with `userId = "user-ac3-login-id"`
  - Then: `RootNavigationCoordinator` observes the `isLoggedIn` change, calls `deriveAppState()`, and sets `appState = .authenticated(userId: "user-ac3-login-id")`; `MainView` renders `HomeView`
  - Verify: `coordinator.appState == .authenticated(userId: "user-ac3-login-id")`; `HomeView` is the active root view; `LoginOrSignUpScreen` is no longer rendered
  - **Failure**: `appState` never transitions to `.authenticated` after a successful login. The coordinator stays on `.unauthenticated`.
  - **Root Cause**: Swift's `@Published` fires its publisher in `willSet`, before the backing storage is updated. The Combine sink in `RootNavigationCoordinator` ignores the published value and instead calls `deriveAppState()`, which reads `authViewModel.isLoggedIn` directly. At the moment the sink executes, the property still holds the old value (`false`), so `deriveAppState()` evaluates `authViewModel.isLoggedIn` as `false` and returns `.unauthenticated`. Once `willSet` completes and the property is stored as `true`, no second Combine event fires, leaving `appState` permanently stuck at `.unauthenticated`.
  - **Affected Files**:
    - [Wishie/Coordinator/RootNavigationCoordinator.swift](Wishie/Coordinator/RootNavigationCoordinator.swift) — lines 13–17: sink reads `deriveAppState()` instead of using the incoming published value
    - [Wishie/Coordinator/RootNavigationCoordinator.swift](Wishie/Coordinator/RootNavigationCoordinator.swift) — lines 30–38: `deriveAppState()` reads `authViewModel.isLoggedIn` from the property, not from the Combine event stream

- [ ] **Scenario: Correct transition animation plays when entering authenticated state** ❌ FAILED
  - Given: `appState-ac3-animation` transitions from `.unauthenticated` to `.authenticated(userId: "user-ac3-anim-id")`
  - When: `MainView` receives the updated `appState` and renders `HomeView`
  - Then: The `.move(edge: .trailing)` animation (or the animation defined in `RootNavigationAnimations` for `unauthenticated → authenticated`) is applied
  - Verify: Transition animation fires and completes within 500ms; `HomeView` is fully visible after animation; no flash or blank frame occurs
  - **Failure**: The `.move(edge: .trailing)` transition on `HomeView` never fires because `appState` never transitions to `.authenticated` (blocked by the same `@Published` willSet bug as Scenario 1).
  - **Root Cause**: The animation transition defined in `MainView` (`.transition(.move(edge: .trailing))` on the `.authenticated` case) is structurally correct. However, it can only play when `appState` actually changes to `.authenticated`. Since the Combine sink in `RootNavigationCoordinator` reads a stale `isLoggedIn` value, `appState` never leaves `.unauthenticated`, and the transition is never evaluated by SwiftUI.
  - **Affected Files**:
    - [Wishie/Coordinator/RootNavigationCoordinator.swift](Wishie/Coordinator/RootNavigationCoordinator.swift) — lines 13–17: same stale-read bug prevents `appState` from reaching `.authenticated`
    - [Wishie/Screens/MainView.swift](Wishie/Screens/MainView.swift) — lines 16–27: transition code is correct but unreachable due to the coordinator bug

- [x] **Scenario: Authenticated session is restored on app relaunch**
  - Given: User `user-ac3-restore` was previously authenticated (`authViewModel-ac3-restore.isLoggedIn = true`, `userId = "user-ac3-restore-id"`, `hasCompletedOnboarding = true`) and the app is relaunched
  - When: `RootNavigationCoordinator` initializes and calls `deriveAppState()`
  - Then: `appState` is set to `.authenticated(userId: "user-ac3-restore-id")` and `HomeView` is rendered directly after the LaunchScreen
  - Verify: `coordinator.appState == .authenticated(userId: "user-ac3-restore-id")`; `WelcomeView` and `LoginOrSignUpScreen` are bypassed; `HomeView` loads immediately

- [x] **Scenario: Logout transitions app state from .authenticated to .unauthenticated**
  - Given: User `user-ac3-logout` is authenticated with `appState-ac3-logout = .authenticated(userId: "user-ac3-logout-id")`
  - When: `RootNavigationCoordinator.logout()` is called
  - Then: `authViewModel-ac3-logout.logOut()` is invoked, `appState` transitions to `.unauthenticated`, and `LoginOrSignUpScreen` is rendered
  - Verify: `coordinator.appState == .unauthenticated`; `HomeView` is no longer rendered; `hasCompletedOnboarding` remains `true` (onboarding is not reset)

---
