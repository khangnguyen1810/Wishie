# Task 2: State & Navigation — AppState and Coordinator Updates

- [ ] 2.1: In `Wishie/Models/AppState.swift` UPDATE:
  - Add `case interestsSetup` to the `AppState` enum, placing it between `unauthenticated` and `authenticated`.
  - The `requiresAuthentication` computed property `switch` must handle the new case — `interestsSetup` returns `false`.

- [ ] 2.2: In `Wishie/Screens/RootNavigationAnimations.swift` UPDATE:
  - Add transition cases to `animationFor(transition:)` for:
    - `(.unauthenticated, .interestsSetup)` → `authToHome`
    - `(.interestsSetup, .authenticated)` → `authToHome`

- [ ] 2.3: In `Wishie/Coordinator/RootNavigationCoordinator.swift` UPDATE:
  - Add `@AppStorage("hasCompletedInterestsSetup") private var hasCompletedInterestsSetup: Bool = false` alongside the existing `hasCompletedOnboarding` property.
  - Add `func completeInterestsSetup()` that sets `hasCompletedInterestsSetup = true` then calls `updateAppState()`.
  - Update `deriveAppState(isLoggedIn:)`: inside the `isLoggedIn && !userId.isEmpty` branch, add `if !hasCompletedInterestsSetup { return .interestsSetup }` before the final `return .authenticated(userId: userId)`.

- [ ] 2.4: In `Wishie/Screens/Auth/AuthViewModel.swift` UPDATE:
  - In `checkToken()`, inside the `Task` block after the successful `getIDToken(forcingRefresh:)` call and BEFORE `await MainActor.run { self.isLoggedIn = true }`, fetch latest user profile data and set `UserDefaults.standard.set(userInfo.hasCompletedInterestsSetup, forKey: "hasCompletedInterestsSetup")`.
  - If the Firestore field is missing for legacy users, rely on `UserModel` default `false` so those users are sent to `interestsSetup` on app reopen.

- [ ] 2.5: In `Wishie/Screens/MainView.swift` UPDATE:
  - Add a `case .interestsSetup:` branch in the `switch rootNavigationCoordinator.appState` block.
  - Render `InterestsSelectionView()` injected with `.environmentObject(authViewModel)` and `.transition(.opacity)`.

---

