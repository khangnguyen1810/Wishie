# EC 6: Back Navigation in Edit Mode Discards Unsaved Changes

- [x] **Scenario: Back Button in Edit Mode Dismisses Without Persisting Changes** ✅ RESOLVED
  - Given: User `"user-ec6-edit-discard"` has previously saved interests `["Gym & Fitness", "Cooking"]`; the user opens `InterestsSelectionView` from `ProfileView` in edit mode (`isOnboarding: false`) and deselects "Cooking" then selects "Hiking"
  - When: The user taps the back button in the `TopAppBar` left slot
  - Then: `InterestsSelectionView` is dismissed via `dismiss()`; no Firestore write is triggered; the user's saved interests remain `["Gym & Fitness", "Cooking"]` in Firestore
  - Verify: The Firestore document for `"user-ec6-edit-discard"` is unchanged; the coordinator state remains `AppState.authenticated`; `ProfileView` is shown
  - **Failure**: No back button exists in the `TopAppBar` leading slot; `InterestsSelectionView` has no edit mode support and no dismiss mechanism; `ProfileView` does not navigate to `InterestsSelectionView` at all.
  - **Root Cause**: The edit mode feature for `InterestsSelectionView` was never implemented. The view is onboarding-only — it has no `isOnboarding` parameter, no `@Environment(\.dismiss)`, and the `TopAppBar` leading slot renders `EmptyView()`. Additionally, `ProfileView`'s `navigationDestination` has no case for `InterestsSelectionView`, and `Route` has no corresponding case.
  - **Affected Files**:
    - `Wishie/Screens/Interests/InterestsSelectionView.swift` — `TopAppBar` leading slot is `EmptyView()` (line 15); no `@Environment(\.dismiss)`; no `isOnboarding` parameter; no conditional back-button rendering for edit mode.
    - `Wishie/Screens/Profile/ProfileView.swift` — `navigationDestination` only handles `Route.editProfile`; no navigation to `InterestsSelectionView`.
    - `Wishie/Models/Route.swift` — no `interestsSelection` case in the `Route` enum.
  - **Resolution**:
    - `InterestsSelectionView`: added `isOnboarding: Bool` parameter (default `true`), `@Environment(\.dismiss)`, conditional back button in `TopAppBar` leading slot that calls `dismiss()` when `!isOnboarding`, conditional button title ("Save & Continue" vs "Save"), `.padding(.bottom, 20)` on the save button, and updated `onChange(of: viewModel.isSaveSuccess)` to dismiss and sync `authViewModel.userInfo.interests` in edit mode instead of calling `completeInterestsSetup()`.
    - `ProfileView`: added an Interests row (via `profileInfoRow` with tap gesture) that pushes `Route.editInterests`, and added `navigationDestination` case for `Route.editInterests` rendering `InterestsSelectionView(isOnboarding: false)`.
    - `Route`: added `editInterests` case.
