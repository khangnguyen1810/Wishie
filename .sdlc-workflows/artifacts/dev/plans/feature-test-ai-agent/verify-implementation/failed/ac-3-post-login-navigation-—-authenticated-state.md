# AC 3: Post-Login Navigation — Authenticated State

- [x] **Scenario: Successful login transitions app state to .authenticated with userId** ✅ RESOLVED
  - Given: User `user-ac3-login` exists with valid credentials, `appState-ac3-login` is `.unauthenticated`, and `authViewModel-ac3-login.isLoggedIn = false`
  - When: The user submits correct credentials on `LoginOrSignUpScreen` and `authViewModel-ac3-login.isLoggedIn` becomes `true` with `userId = "user-ac3-login-id"`
  - Then: `RootNavigationCoordinator` observes the `isLoggedIn` change, calls `deriveAppState()`, and sets `appState = .authenticated(userId: "user-ac3-login-id")`; `MainView` renders `HomeView`
  - Verify: `coordinator.appState == .authenticated(userId: "user-ac3-login-id")`; `HomeView` is the active root view; `LoginOrSignUpScreen` is no longer rendered
  - **Resolution**: The `$isLoggedIn` Combine sink was changed to capture the incoming `isLoggedIn` parameter from the stream and pass it directly to `deriveAppState(isLoggedIn:)`. `deriveAppState` was refactored to accept `isLoggedIn: Bool` as a parameter instead of reading `authViewModel.isLoggedIn` from the property. This eliminates the `willSet` stale-read: the new value emitted by `@Published` is used before the backing store assignment completes, so `appState` transitions correctly to `.authenticated`.
  - **Affected Files**:
    - [Wishie/Coordinator/RootNavigationCoordinator.swift](Wishie/Coordinator/RootNavigationCoordinator.swift) — sink updated to `{ isLoggedIn in ... deriveAppState(isLoggedIn: isLoggedIn) }`; `deriveAppState` refactored to accept `isLoggedIn: Bool` parameter

- [x] **Scenario: Correct transition animation plays when entering authenticated state** ✅ RESOLVED
  - Given: `appState-ac3-animation` transitions from `.unauthenticated` to `.authenticated(userId: "user-ac3-anim-id")`
  - When: `MainView` receives the updated `appState` and renders `HomeView`
  - Then: The `.move(edge: .trailing)` animation (or the animation defined in `RootNavigationAnimations` for `unauthenticated → authenticated`) is applied
  - Verify: Transition animation fires and completes within 500ms; `HomeView` is fully visible after animation; no flash or blank frame occurs
  - **Resolution**: Resolved as a consequence of fixing Scenario 1. With `appState` now correctly transitioning to `.authenticated`, `MainView` re-evaluates its `switch` on `rootNavigationCoordinator.appState`, SwiftUI replaces `LoginOrSignUpScreen` with `HomeView`, and the `.move(edge: .trailing)` transition defined on the `.authenticated` case fires as designed. No changes were required in `MainView`.
  - **Affected Files**:
    - [Wishie/Coordinator/RootNavigationCoordinator.swift](Wishie/Coordinator/RootNavigationCoordinator.swift) — same fix as Scenario 1 unblocks this transition path
    - [Wishie/Screens/MainView.swift](Wishie/Screens/MainView.swift) — no changes needed; transition code was already correct

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
