# EC 11: Successful Save in Edit Mode Does Not Trigger Coordinator State Transition

- [x] **Scenario: Saving Interests in Edit Mode Dismisses View Without Advancing Coordinator State** ✅ RESOLVED
  - Given: User `"user-ec11-edit-save"` is authenticated (`AppState.authenticated`) and opens `InterestsSelectionView` from `ProfileView` in edit mode (`isOnboarding: false`) with chips "Reading" and "Yoga" selected
  - When: The user taps the save action
  - Then: Firestore is updated with the new interests; `InterestsSelectionView` is dismissed via `dismiss()`; the coordinator state remains `AppState.authenticated`; no navigation to HomeView restart occurs
  - Verify: The coordinator state is unchanged at `AppState.authenticated`; `ProfileView` is shown after dismissal; the Firestore document for `"user-ec11-edit-save"` contains the updated interests
  - **Failure**: The implementation has no edit mode concept. `InterestsSelectionView` does not accept an `isOnboarding` parameter, does not call `dismiss()`, and always invokes `rootNavigationCoordinator.completeInterestsSetup()` on save success regardless of context. Additionally, `ProfileView` has no navigation path to `InterestsSelectionView`.
  - **Root Cause**: `InterestsSelectionView` was implemented only for the onboarding flow. No `isOnboarding: Bool` (or equivalent) parameter was added to distinguish edit mode from onboarding mode. There is no `@Environment(\.dismiss)` property, no `dismiss()` call, and no conditional branching in the `.onChange(of: viewModel.isSaveSuccess)` handler to route behavior by mode.
  - **Affected Files**:
    - `Wishie/Screens/Interests/InterestsSelectionView.swift` — missing `isOnboarding` parameter in `init()`, missing `@Environment(\.dismiss) private var dismiss`, and `.onChange(of: viewModel.isSaveSuccess)` unconditionally calls `rootNavigationCoordinator.completeInterestsSetup()` instead of `dismiss()` in edit mode
    - `Wishie/Screens/Profile/ProfileView.swift` — no navigation destination or sheet/fullScreenCover presenting `InterestsSelectionView` for editing interests
  - **Actions Taken**:
    - `InterestsSelectionView`: Added `isOnboarding: Bool` parameter to `init()` (defaults to `true`); added `@Environment(\.dismiss) private var dismiss`; added conditional back button in `TopAppBar` leading slot for edit mode; changed button title to `"Save & Continue"` in onboarding and `"Save"` in edit mode; added `.padding(.bottom, 20)` to `WishieButton`; updated `.onChange(of: viewModel.isSaveSuccess)` to call `rootNavigationCoordinator.completeInterestsSetup()` in onboarding mode and `authViewModel.userInfo.interests = Array(viewModel.selectedInterestIds); dismiss()` in edit mode
    - `Route.swift`: Added `editInterests` case
    - `ProfileView.swift`: Added tappable "Interests" row in the profile info section that appends `Route.editInterests` to the navigation path; added `case .editInterests` in `navigationDestination` presenting `InterestsSelectionView(isOnboarding: false)`
