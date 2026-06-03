# AC 9: Edit Mode Accessible from Profile Screen

- [x] **Scenario: User opens Interests edit mode from the Profile screen** ✅ RESOLVED
  - Given: user `user-ac9-profile` is authenticated, `hasCompletedInterestsSetup` is `true`, and they are on the Profile screen
  - When: the user taps the "Interests" row in ProfileView
  - Then: `InterestsSelectionView` opens with `isOnboarding: false` via the Profile `NavigationStack`; a back button is visible in the TopAppBar left slot
  - Verify: the `Route` enum resolves `.editInterests`; the view is pushed onto the Profile navigation stack; `isOnboarding` flag is `false`
  - **Resolution**:
    1. Added `.editInterests` case to `Route` enum in `Wishie/Models/Route.swift`.
    2. Added tappable "Interests" row to `ProfileView` that appends `Route.editInterests` to the navigation path.
    3. Added `.editInterests` case in `ProfileView.navigationDestination(for: Route.self)` that pushes `InterestsSelectionView(isOnboarding: false)`.
    4. Added `isOnboarding: Bool` parameter to `InterestsSelectionView.init()` (defaults to `true` for existing onboarding usage).
    5. TopAppBar left slot now conditionally renders a back button (`dismiss()`) when `!isOnboarding`; `EmptyView()` otherwise.
    6. Save button title switches between "Save & Continue" (onboarding) and "Save" (edit mode); `.padding(.bottom, 20)` added per spec.
    7. On save success in edit mode: `authViewModel.userInfo.interests` is updated with saved selections and `dismiss()` is called.
  - **Affected Files**:
    - `Wishie/Models/Route.swift` — added `.editInterests` case
    - `Wishie/Screens/Profile/ProfileView.swift` — added "Interests" row and `.editInterests` navigationDestination
    - `Wishie/Screens/Interests/InterestsSelectionView.swift` — added `isOnboarding` parameter, conditional back button, bottom padding, and mode-aware success handler

