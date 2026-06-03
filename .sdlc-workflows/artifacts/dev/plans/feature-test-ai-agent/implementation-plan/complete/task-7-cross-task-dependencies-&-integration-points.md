# Task 7: Cross-task Dependencies & Integration Points

- Task 1 (AppState model) is a prerequisite for Task 2
- Task 2 (RootNavigationCoordinator) depends on Task 1 and `AuthViewModel` from [Wishie/Screens/Auth/AuthViewModel.swift](Wishie/Screens/Auth/AuthViewModel.swift)
- Task 3 (RootNavigationAnimations) is independent but used in Task 5
- Task 4 (WishieApp update) depends on Task 1 and Task 2; must be completed before Task 5
- Task 5 (MainView refactor) depends on Tasks 1, 2, 3, and 4; final step in navigation refactor
- Task 6 (Testing & validation) validates all tasks 1-5

## File Dependency Graph

```
WishieApp.swift
  ├── imports AuthViewModel (existing)
  ├── creates @StateObject RootNavigationCoordinator (new - Task 2)
  ├── injects AuthViewModel + RootNavigationCoordinator as EnvironmentObject
  └── displays MainView

MainView.swift (refactored - Task 5)
  ├── receives @EnvironmentObject RootNavigationCoordinator (new - Task 2)
  ├── reads @Published appState: AppState (new - Task 1)
  ├── renders WelcomeView, LoginOrSignUpScreen, or HomeView based on appState
  └── applies animations from RootNavigationAnimations (new - Task 3)

RootNavigationCoordinator (new - Task 2)
  ├── observes AuthViewModel.isLoggedIn (existing)
  ├── observes AppStorage("hasCompletedOnboarding") (existing)
  ├── derives AppState (new - Task 1)
  ├── provides completeOnboarding() method (called by OnboardingContainerView)
  └── provides logout() method (called by HomeView settings)

AppState enum (new - Task 1)
  └── used by RootNavigationCoordinator and MainView for type-safe state representation

RootNavigationAnimations (new - Task 3)
  └── provides animation definitions for MainView state transitions
```

---

