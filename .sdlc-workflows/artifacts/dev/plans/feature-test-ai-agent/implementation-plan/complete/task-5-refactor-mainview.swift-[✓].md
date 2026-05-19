# Task 5: Refactor MainView.swift [ ]

Remove local navigation logic; render views based on `RootNavigationCoordinator.appState` with defined animations. Simplify view structure.

- 5.1: In [Wishie/Screens/MainView.swift](Wishie/Screens/MainView.swift) **UPDATE**:
  - Remove property `@AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false` (no longer needed here)
  - Remove property `@EnvironmentObject var authViewModel: AuthViewModel` (still have access via coordinator; if needed, can keep for AuthViewModel operations, but recommended removal)
  - Add new property `@EnvironmentObject var rootNavigationCoordinator: RootNavigationCoordinator`
  - Replace entire `body` with simplified conditional rendering based on `rootNavigationCoordinator.appState`:
    ```swift
    var body: some View {
        switch rootNavigationCoordinator.appState {
        case .welcome:
            WelcomeView()
                .transition(.opacity)
        case .unauthenticated:
            LoginOrSignUpScreen()
                .transition(.move(edge: .leading))
        case .authenticated(let userId):
            HomeView()
                .transition(.move(edge: .trailing))
        }
    }
    ```
  - Replace `.transition()` modifiers with calls to `RootNavigationAnimations.animationFor()` if animations are extracted to separate layer, or use defined animations directly
  - Wrap entire switch in animation modifier if needed: `.animation(.easeInOut(duration: 0.4), value: rootNavigationCoordinator.appState)` to animate between states

- 5.2: In [Wishie/Screens/MainView.swift](Wishie/Screens/MainView.swift) **VALIDATE**:
  - Ensure `WelcomeView()` is used (should have no parameters or existing parameters unchanged)
  - Ensure `LoginOrSignUpScreen()` is used (should have no parameters or existing parameters unchanged)
  - Ensure `HomeView()` is used (should receive `authViewModel` if it's a dependency; add `.environmentObject(authViewModel)` if coordinator is not injecting auth model)
  - Check that nested navigation via `Route` enum in HomeView remains untouched (HomeView manages its own NavigationStack internally)
  - If `LoginOrSignUpScreen` or other auth screens read from coordinator, add `.environmentObject(rootNavigationCoordinator)` for their state updates

---

