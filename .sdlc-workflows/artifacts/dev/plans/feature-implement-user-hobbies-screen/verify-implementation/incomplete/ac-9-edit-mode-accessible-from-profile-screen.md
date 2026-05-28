# AC 9: Edit Mode Accessible from Profile Screen

- [ ] **Scenario: User opens Interests edit mode from the Profile screen** ❌ FAILED
  - Given: user `user-ac9-profile` is authenticated, `hasCompletedInterestsSetup` is `true`, and they are on the Profile screen
  - When: the user taps the "Interests" row in ProfileView
  - Then: `InterestsSelectionView` opens with `isOnboarding: false` via the Profile `NavigationStack`; a back button is visible in the TopAppBar left slot
  - Verify: the `Route` enum resolves `.interests`; the view is pushed onto the Profile navigation stack; `isOnboarding` flag is `false`
  - **Failure**: Multiple required implementations are missing entirely
  - **Root Cause**:
    1. `Route` enum (`Wishie/Models/Route.swift`) has no `.interests` case — only `createNew`, `scanQRCode`, `createSuccess`, `qrCodeScreen`, `wishListInfoScreen`, `wishListDetailScreen`, `editProfile` are defined.
    2. `ProfileView` (`Wishie/Screens/Profile/ProfileView.swift` lines 61–65) renders only Full Name, Date of Birth, Email, and Phone rows — no "Interests" tappable row exists.
    3. `ProfileView.navigationDestination(for: Route.self)` (line ~86) handles only `.editProfile`; no `.interests` destination is registered.
    4. `InterestsSelectionView.init()` (`Wishie/Screens/Interests/InterestsSelectionView.swift` lines 8–10) accepts no parameters — there is no `isOnboarding: Bool` flag at all.
    5. `InterestsSelectionView` TopAppBar left slot (line 16) renders `EmptyView()` — no back button is present regardless of mode.
  - **Affected Files**:
    - `Wishie/Models/Route.swift` — missing `.interests` case
    - `Wishie/Screens/Profile/ProfileView.swift` — missing "Interests" row and `.interests` navigationDestination
    - `Wishie/Screens/Interests/InterestsSelectionView.swift` — missing `isOnboarding` parameter and conditional back button
