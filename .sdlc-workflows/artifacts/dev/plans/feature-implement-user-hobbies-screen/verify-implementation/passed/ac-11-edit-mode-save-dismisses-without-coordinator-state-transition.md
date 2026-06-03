# AC 11: Edit Mode Save Dismisses Without Coordinator State Transition

- [x] **Scenario: Saving interests in edit mode dismisses the view without triggering onboarding routing** ✅ RESOLVED
  - Given: `InterestsSelectionView` is open with `isOnboarding: false` for user `user-ac11-edit` who modifies their selected hobbies
  - When: the user taps the save button
  - Then: the updated interests array and `hasCompletedInterestsSetup: true` are written to Firestore; `InterestsSelectionView` is dismissed; the user returns to ProfileView; `AppState` does NOT change
  - Verify: `RootNavigationCoordinator` state remains `AppState.authenticated`; no transition to HomeView occurs; ProfileView is visible after dismissal
  - **Resolution**:
    1. Added `isOnboarding: Bool = true` parameter to `InterestsSelectionView.init()` and stored it as `private let isOnboarding: Bool`.
    2. Added `@Environment(\.dismiss) private var dismiss` to `InterestsSelectionView`.
    3. Updated `onChange(of: viewModel.isSaveSuccess)` to branch: if `isOnboarding`, call `rootNavigationCoordinator.completeInterestsSetup()`; otherwise update `authViewModel.userInfo.interests` and call `dismiss()`.
    4. Added `case editInterests` to `Route` enum in `Wishie/Models/Route.swift`.
    5. Added an "Interests" tappable row in `ProfileView` that appends `Route.editInterests` to the navigation path.
    6. Added `.editInterests` case in `ProfileView` `navigationDestination` that presents `InterestsSelectionView(isOnboarding: false)`.
    7. Added `.padding(.bottom, 20)` to the save button to prevent it from sticking at the bottom of the screen.

