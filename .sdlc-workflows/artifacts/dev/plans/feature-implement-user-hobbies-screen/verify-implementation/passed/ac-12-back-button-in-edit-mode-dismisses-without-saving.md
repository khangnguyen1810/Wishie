# AC 12: Back Button in Edit Mode Dismisses Without Saving

- [x] **Scenario: Tapping the back button in edit mode dismisses the view without persisting changes** ✅ RESOLVED
  - Given: `InterestsSelectionView` is open with `isOnboarding: false` for user `user-ac12-backdismiss` who has modified the chip selection
  - When: the user taps the back button in the TopAppBar left slot
  - Then: `InterestsSelectionView` is dismissed; no Firestore write is performed; the previously saved interests remain unchanged
  - Verify: Firestore document for `user-ac12-backdismiss` retains the original interests array; ProfileView is displayed after dismissal
  - **Failure**: No back button exists in the TopAppBar leading slot; `InterestsSelectionView` has no `isOnboarding` parameter to differentiate edit mode; dismiss-without-saving behavior is entirely absent.
  - **Root Cause**:
    1. `InterestsSelectionView.init()` accepts no parameters — there is no `isOnboarding: Bool` flag to enable edit-mode-specific UI.
    2. The `TopAppBar` leading slot renders `EmptyView()` unconditionally — no back button is wired up for edit mode.
    3. No `@Environment(\.dismiss)` or equivalent dismiss action exists in the view, so tapping a back button (even if rendered) would do nothing.
    4. The `onChange(of: viewModel.isSaveSuccess)` handler calls `rootNavigationCoordinator.completeInterestsSetup()` on success, but there is no corresponding dismiss path for the back/cancel flow.
  - **Affected Files**:
    - `Wishie/Screens/Interests/InterestsSelectionView.swift` — missing `isOnboarding` parameter, leading slot is `EmptyView()`, no dismiss logic
  - **Resolution**:
    - Added `isOnboarding: Bool = true` parameter to `init()` so edit mode can be signalled with `isOnboarding: false`; `MainView` passes `isOnboarding: true` explicitly to preserve onboarding behaviour
    - Added `@Environment(\.dismiss) private var dismiss` to enable programmatic dismissal
    - Replaced unconditional `EmptyView()` in the TopAppBar leading slot with a conditional back button (matching the `ProfileView` style) that calls `dismiss()` — rendered only when `isOnboarding == false`
    - Updated `onChange(of: viewModel.isSaveSuccess)` to call `dismiss()` in edit mode instead of `completeInterestsSetup()`, ensuring no coordinator navigation occurs on back
    - Added `.padding(.bottom, 20)` to the save button so it does not stick to the bottom edge of the screen
