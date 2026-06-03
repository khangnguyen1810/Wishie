# Task 6: Cross-Platform Testing & Validation [ ]

Verify state transitions, animations, and backward compatibility without introducing regressions.

- 6.1: Manual validation (no automated tests per project guidelines):
  - Launch app and verify LaunchScreen displays for ~0.5 seconds, then MainView appears
  - Cold start without onboarding: should show WelcomeView
  - Click "Let's get started": should transition to onboarding flow (maintained in `OnboardingContainerView`)
  - Complete onboarding: should transition to LoginOrSignUpScreen with `.move(edge: .leading)` animation
  - Login successfully: should transition to HomeView with `.move(edge: .trailing)` animation
  - Verify HomeView's nested Route navigation still works (create list, scan QR, etc.)
  - Logout from HomeView: should return to LoginOrSignUpScreen
  - Re-login: should show HomeView again without affecting onboarding flag
  - Force restart app (simulate): should restore to previous state (HomeView if logged in, LoginOrSignUpScreen if not but onboarded, WelcomeView otherwise)

- 6.2: Code review checklist:
  - [ ] `AppState` enum is Hashable and covers all navigation paths
  - [ ] `RootNavigationCoordinator` properly observes both `authViewModel.isLoggedIn` and `hasCompletedOnboarding`
  - [ ] `RootNavigationCoordinator.deriveAppState()` correctly handles all state combinations
  - [ ] `WishieApp.swift` injects both `authViewModel` and `rootNavigationCoordinator` as EnvironmentObjects
  - [ ] `MainView.swift` uses only `rootNavigationCoordinator.appState` for rendering decisions
  - [ ] Animations complete within 500ms (verify visually or via Xcode performance tools)
  - [ ] No console warnings about missing EnvironmentObjects
  - [ ] LaunchScreen logic remains functional and timing preserved
  - [ ] Onboarding flow (WelcomeView → OnboardingContainerView) still functions
  - [ ] Existing nested navigation (HomeView → Route destinations) is untouched

---

