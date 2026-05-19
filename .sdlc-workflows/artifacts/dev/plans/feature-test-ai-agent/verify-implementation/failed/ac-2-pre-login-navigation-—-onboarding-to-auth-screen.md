# AC 2: Pre-Login Navigation — Onboarding to Auth Screen

- [x] **Scenario: Completing onboarding transitions app state from .welcome to .unauthenticated** ✅ RESOLVED
  - Given: `appState-ac2-onboard` is `.welcome`, the user `user-ac2-onboard` is on `WelcomeView` and proceeds through `OnboardingContainerView`
  - When: `RootNavigationCoordinator.completeOnboarding()` is called after the user finishes the onboarding flow
  - Then: `hasCompletedOnboarding` is persisted as `true` via `AppStorage`, `deriveAppState()` sets `appState = .unauthenticated`, and `MainView` renders `LoginOrSignUpScreen`
  - Verify: `coordinator.appState == .unauthenticated`; `LoginOrSignUpScreen` is the active root view; `WelcomeView` is no longer rendered; transition animation completes within 500ms
  - **Failure**: `coordinator.appState` remains `.welcome` after onboarding — `completeOnboarding()` is never called; `LoginOrSignUpScreen` appears via a `NavigationStack` push inside `OnboardingView`, not through `MainView`'s coordinator-driven switch
  - **Root Cause**: `OnboardingView`'s "Continue" button writes `UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")` directly and sets a local `@State var hasCompletedOnboarding` to trigger `navigationDestination`. It never accesses `RootNavigationCoordinator` or calls `completeOnboarding()`. The coordinator observes only `authViewModel.$isLoggedIn` (via Combine) and has no subscription for `@AppStorage` changes; so the external UserDefaults write does not trigger `deriveAppState()`.
  - **Resolution**: Removed `NavigationStack`, `navigationDestination`, and local `@State var hasCompletedOnboarding` from `OnboardingView`. Added `@EnvironmentObject var coordinator: RootNavigationCoordinator`. The "Continue" button now calls `coordinator.completeOnboarding()`, which sets `@AppStorage hasCompletedOnboarding = true` and calls `deriveAppState()`, transitioning `appState` to `.unauthenticated`. `MainView` re-renders `LoginOrSignUpScreen` via the coordinator-driven switch.
  - **Affected Files**:
    - [Wishie/Screens/OnboardingContainerView.swift](Wishie/Screens/OnboardingContainerView.swift) — `OnboardingView` button action (line ~63): `UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding"); hasCompletedOnboarding = true` with no coordinator reference
    - [Wishie/Coordinator/RootNavigationCoordinator.swift](Wishie/Coordinator/RootNavigationCoordinator.swift) — `init` only subscribes to `authViewModel.$isLoggedIn`; no observation of `hasCompletedOnboarding` changes from external sources

- [x] **Scenario: LoginOrSignUpScreen is displayed with correct transition animation when entering auth state** ✅ RESOLVED
  - Given: `appState-ac2-transition` transitions from `.welcome` to `.unauthenticated` for user `user-ac2-transition`
  - When: `MainView` receives the updated `appState` from the coordinator
  - Then: The `.opacity` transition animation is applied (as defined in `RootNavigationAnimations`), and `LoginOrSignUpScreen` appears with no observable lag
  - Verify: The transition animation defined for `welcome → unauthenticated` is applied; animation completes within 500ms; no layout artifacts during transition
  - **Failure**: (1) `coordinator.appState` never transitions from `.welcome` to `.unauthenticated` during normal onboarding (see Scenario 1 failure), so `MainView` never receives the state update and never renders `LoginOrSignUpScreen` through the coordinator. (2) When `MainView` does switch to `.unauthenticated`, the `LoginOrSignUpScreen` uses `.transition(.move(edge: .leading))`, not `.opacity` as described in the scenario. (3) `RootNavigationAnimations.animationFor()` is defined but never invoked anywhere; animation context comes from `WishieApp`'s hardcoded `.animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)`.
  - **Root Cause**: `completeOnboarding()` is never called (Scenario 1 root cause), so the `appState` transition the scenario depends on never occurs in practice. Additionally, `MainView` does not apply `.animation(_:value: rootNavigationCoordinator.appState)` on its switch body, so transitions only animate when the WishieApp-level `.animation` modifiers happen to fire.
  - **Resolution**: (1) Fixed by Scenario 1 resolution — `coordinator.completeOnboarding()` now fires, transitioning `appState` to `.unauthenticated`. (2) Changed `LoginOrSignUpScreen`'s transition in `MainView` from `.transition(.move(edge: .leading))` to `.transition(.opacity)`. (3) Added `@State private var currentAnimation` to `MainView` and applied `.animation(currentAnimation, value: rootNavigationCoordinator.appState)` with `.onChange(of:)` calling `RootNavigationAnimations.animationFor(transition:)` to select the correct animation per state transition. (4) Converted `WishieApp`'s `@State private var rootNavigationCoordinator` to `@StateObject private var coordinator` (initialized via `init()`) so `coordinator.appState` drives the outer animation correctly.
  - **Affected Files**:
    - [Wishie/Screens/MainView.swift](Wishie/Screens/MainView.swift) — `.unauthenticated` case uses `.transition(.move(edge: .leading))` (not `.opacity`); no `.animation(_:value:)` wrapping the switch
    - [Wishie/Screens/RootNavigationAnimations.swift](Wishie/Screens/RootNavigationAnimations.swift) — `animationFor()` method is defined but unused throughout the codebase
    - [Wishie/WishieApp.swift](Wishie/WishieApp.swift) — animation context is `value: hasCompletedOnboarding` and `value: authViewModel.isLoggedIn`, neither of which is `coordinator.appState`

- [x] **Scenario: AppStorage persists onboarding completion across app restarts**
  - Given: User `user-ac2-persist` previously completed onboarding (`hasCompletedOnboarding = true`) and is not logged in (`authViewModel-ac2-persist.isLoggedIn = false`)
  - When: The app is terminated and relaunched, and `RootNavigationCoordinator` re-initializes
  - Then: `deriveAppState()` reads `hasCompletedOnboarding = true` and `isLoggedIn = false`, setting `appState = .unauthenticated`; `WelcomeView` is never shown
  - Verify: `coordinator.appState == .unauthenticated` on launch; `LoginOrSignUpScreen` is rendered directly; onboarding is not replayed

---
