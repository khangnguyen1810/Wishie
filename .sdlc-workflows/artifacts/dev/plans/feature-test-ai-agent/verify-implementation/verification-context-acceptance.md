# Verification Context — Acceptance Scenarios

## Purpose

Define testable acceptance scenarios in Given/When/Then format to verify the implementation meets functional requirements and success criteria.
This document serves as the single source of truth for acceptance verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "user-ac1-login", "product-ac2-checkout"). No two scenarios should share mutable state.

## Acceptance Scenarios:

---

### AC 1: App Launch — Before Onboarding (No Prior State)

- [ ] **Scenario: Fresh install shows WelcomeView when onboarding has not been completed**
  - Given: A device with no prior app data, `hasCompletedOnboarding` is `false`, and `authViewModel-ac1-fresh.isLoggedIn` is `false`
  - When: The app launches and the LaunchScreen finishes its display cycle in `WishieApp.swift`
  - Then: `RootNavigationCoordinator` derives `appState = .welcome` and `MainView` renders `WelcomeView`
  - Verify: `appState` equals `.welcome`; `WelcomeView` is the active root view; no `LoginOrSignUpScreen` or `HomeView` is visible

- [ ] **Scenario: RootNavigationCoordinator initializes with .welcome as the default state**
  - Given: A `RootNavigationCoordinator` instance initialized with `authViewModel-ac1-coordinator` where `isLoggedIn = false` and `hasCompletedOnboarding = false`
  - When: The coordinator's `init(authViewModel:)` completes and `deriveAppState()` is called
  - Then: `appState` is set to `.welcome` without any further user interaction
  - Verify: `coordinator.appState == .welcome`; no state derivation errors; initial state is stable

---

### AC 2: Pre-Login Navigation — Onboarding to Auth Screen

- [ ] **Scenario: Completing onboarding transitions app state from .welcome to .unauthenticated**
  - Given: `appState-ac2-onboard` is `.welcome`, the user `user-ac2-onboard` is on `WelcomeView` and proceeds through `OnboardingContainerView`
  - When: `RootNavigationCoordinator.completeOnboarding()` is called after the user finishes the onboarding flow
  - Then: `hasCompletedOnboarding` is persisted as `true` via `AppStorage`, `deriveAppState()` sets `appState = .unauthenticated`, and `MainView` renders `LoginOrSignUpScreen`
  - Verify: `coordinator.appState == .unauthenticated`; `LoginOrSignUpScreen` is the active root view; `WelcomeView` is no longer rendered; transition animation completes within 500ms

- [ ] **Scenario: LoginOrSignUpScreen is displayed with correct transition animation when entering auth state**
  - Given: `appState-ac2-transition` transitions from `.welcome` to `.unauthenticated` for user `user-ac2-transition`
  - When: `MainView` receives the updated `appState` from the coordinator
  - Then: The `.opacity` transition animation is applied (as defined in `RootNavigationAnimations`), and `LoginOrSignUpScreen` appears with no observable lag
  - Verify: The transition animation defined for `welcome → unauthenticated` is applied; animation completes within 500ms; no layout artifacts during transition

- [ ] **Scenario: AppStorage persists onboarding completion across app restarts**
  - Given: User `user-ac2-persist` previously completed onboarding (`hasCompletedOnboarding = true`) and is not logged in (`authViewModel-ac2-persist.isLoggedIn = false`)
  - When: The app is terminated and relaunched, and `RootNavigationCoordinator` re-initializes
  - Then: `deriveAppState()` reads `hasCompletedOnboarding = true` and `isLoggedIn = false`, setting `appState = .unauthenticated`; `WelcomeView` is never shown
  - Verify: `coordinator.appState == .unauthenticated` on launch; `LoginOrSignUpScreen` is rendered directly; onboarding is not replayed

---

### AC 3: Post-Login Navigation — Authenticated State

- [ ] **Scenario: Successful login transitions app state to .authenticated with userId**
  - Given: User `user-ac3-login` exists with valid credentials, `appState-ac3-login` is `.unauthenticated`, and `authViewModel-ac3-login.isLoggedIn = false`
  - When: The user submits correct credentials on `LoginOrSignUpScreen` and `authViewModel-ac3-login.isLoggedIn` becomes `true` with `userId = "user-ac3-login-id"`
  - Then: `RootNavigationCoordinator` observes the `isLoggedIn` change, calls `deriveAppState()`, and sets `appState = .authenticated(userId: "user-ac3-login-id")`; `MainView` renders `HomeView`
  - Verify: `coordinator.appState == .authenticated(userId: "user-ac3-login-id")`; `HomeView` is the active root view; `LoginOrSignUpScreen` is no longer rendered

- [ ] **Scenario: Correct transition animation plays when entering authenticated state**
  - Given: `appState-ac3-animation` transitions from `.unauthenticated` to `.authenticated(userId: "user-ac3-anim-id")`
  - When: `MainView` receives the updated `appState` and renders `HomeView`
  - Then: The `.move(edge: .trailing)` animation (or the animation defined in `RootNavigationAnimations` for `unauthenticated → authenticated`) is applied
  - Verify: Transition animation fires and completes within 500ms; `HomeView` is fully visible after animation; no flash or blank frame occurs

- [ ] **Scenario: Authenticated session is restored on app relaunch**
  - Given: User `user-ac3-restore` was previously authenticated (`authViewModel-ac3-restore.isLoggedIn = true`, `userId = "user-ac3-restore-id"`, `hasCompletedOnboarding = true`) and the app is relaunched
  - When: `RootNavigationCoordinator` initializes and calls `deriveAppState()`
  - Then: `appState` is set to `.authenticated(userId: "user-ac3-restore-id")` and `HomeView` is rendered directly after the LaunchScreen
  - Verify: `coordinator.appState == .authenticated(userId: "user-ac3-restore-id")`; `WelcomeView` and `LoginOrSignUpScreen` are bypassed; `HomeView` loads immediately

- [ ] **Scenario: Logout transitions app state from .authenticated to .unauthenticated**
  - Given: User `user-ac3-logout` is authenticated with `appState-ac3-logout = .authenticated(userId: "user-ac3-logout-id")`
  - When: `RootNavigationCoordinator.logout()` is called
  - Then: `authViewModel-ac3-logout.logOut()` is invoked, `appState` transitions to `.unauthenticated`, and `LoginOrSignUpScreen` is rendered
  - Verify: `coordinator.appState == .unauthenticated`; `HomeView` is no longer rendered; `hasCompletedOnboarding` remains `true` (onboarding is not reset)

---

### AC 4: No Onboarding Access — Unauthenticated Fallback State

- [ ] **Scenario: User without active session lands on LoginOrSignUpScreen after onboarding is complete**
  - Given: User `user-ac4-noauth` has `hasCompletedOnboarding = true` but no active session (`authViewModel-ac4-noauth.isLoggedIn = false`)
  - When: The app launches and `RootNavigationCoordinator` derives state
  - Then: `appState = .unauthenticated` and `LoginOrSignUpScreen` is rendered; user is not redirected to `WelcomeView` or `HomeView`
  - Verify: `coordinator.appState == .unauthenticated`; correct screen is shown without intermediate flickers; `WelcomeView` is not shown

- [ ] **Scenario: Coordinator remains .unauthenticated when login fails, with no state regression to .welcome**
  - Given: User `user-ac4-fail` has `hasCompletedOnboarding = true` and is on `LoginOrSignUpScreen` (`appState-ac4-fail = .unauthenticated`)
  - When: The user submits invalid credentials and `authViewModel-ac4-fail.isLoggedIn` remains `false`
  - Then: `RootNavigationCoordinator` does not alter `appState`; it remains `.unauthenticated`; the user stays on `LoginOrSignUpScreen`
  - Verify: `coordinator.appState == .unauthenticated`; no navigation to `.welcome` or `.authenticated`; error feedback is provided to the user via `AuthViewModel`

- [ ] **Scenario: Coordinator is injectable as EnvironmentObject for access throughout the view hierarchy**
  - Given: `RootNavigationCoordinator` instance `coordinator-ac4-env` is created in `WishieApp.swift` and passed as an `@EnvironmentObject` to `MainView`
  - When: A nested view in the hierarchy (e.g., within `HomeView`) reads the coordinator from the environment
  - Then: The coordinator instance is accessible and its `appState` reflects the current navigation state without requiring direct initialization
  - Verify: `@EnvironmentObject var coordinator: RootNavigationCoordinator` resolves without a fatal error; `coordinator.appState` returns the correct current state

---

### AC 5: Scalability — State Model and Navigation Extensibility

- [ ] **Scenario: AppState enum enforces valid state combinations via type safety**
  - Given: `AppState-ac5-typesafe` enum is defined with `.welcome`, `.unauthenticated`, and `.authenticated(userId: String)` cases
  - When: A switch statement or pattern match is performed over all `AppState` cases
  - Then: The compiler enforces exhaustive handling of all cases; invalid or undefined states cannot be represented
  - Verify: Adding a new case to `AppState` causes a compile-time error at unhandled switch sites, confirming type safety and extensibility is enforced

- [ ] **Scenario: MainView renders only the view corresponding to current appState with no logic leakage**
  - Given: `MainView-ac5-clean` receives `appState` via coordinator and contains no direct references to `AppStorage`, `AuthViewModel.isLoggedIn`, or independent state sources
  - When: `appState` changes to any of `.welcome`, `.unauthenticated`, or `.authenticated`
  - Then: `MainView` renders the correct root view (`WelcomeView`, `LoginOrSignUpScreen`, or `HomeView`) exclusively based on `appState`
  - Verify: `MainView` source contains no `@AppStorage` or direct `authViewModel` state reads; view selection is a pure function of `appState`
