# AC 11: Edit Mode Save Dismisses Without Coordinator State Transition

- [ ] **Scenario: Saving interests in edit mode dismisses the view without triggering onboarding routing** ❌ FAILED
  - Given: `InterestsSelectionView` is open with `isOnboarding: false` for user `user-ac11-edit` who modifies their selected hobbies
  - When: the user taps the save button
  - Then: the updated interests array and `hasCompletedInterestsSetup: true` are written to Firestore; `InterestsSelectionView` is dismissed; the user returns to ProfileView; `AppState` does NOT change
  - Verify: `RootNavigationCoordinator` state remains `AppState.authenticated`; no transition to HomeView occurs; ProfileView is visible after dismissal
  - **Failure**: Edit mode (`isOnboarding: false`) is entirely unimplemented — the view has no edit mode concept, no dismiss mechanism, and no entry point from ProfileView.
  - **Root Cause**:
    1. `InterestsSelectionView.init()` accepts no parameters — there is no `isOnboarding: Bool` flag to distinguish edit mode from onboarding mode.
    2. The `onChange(of: viewModel.isSaveSuccess)` handler unconditionally calls `rootNavigationCoordinator.completeInterestsSetup()` on save success. There is no branch to call `@Environment(\.dismiss)` when in edit mode.
    3. `ProfileView` has no sheet or navigation link pointing to `InterestsSelectionView`. The `Route` enum (`Wishie/Models/Route.swift`) has no `editInterests` case.
    4. `InterestsSelectionView` is only reachable via the `AppState.interestsSetup` branch in `MainView` — it cannot be presented as a sheet from `ProfileView`.
  - **Affected Files**:
    - `Wishie/Screens/Interests/InterestsSelectionView.swift` — missing `isOnboarding: Bool` init parameter, missing `@Environment(\.dismiss)` usage, `onChange` always calls `completeInterestsSetup()` with no edit-mode branch
    - `Wishie/Screens/Profile/ProfileView.swift` — no sheet or `NavigationLink` to `InterestsSelectionView`
    - `Wishie/Models/Route.swift` — no `editInterests` case defined
