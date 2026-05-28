# EC 2: Legacy User Document Missing hasCompletedInterestsSetup Field

- [x] **Scenario: Legacy User Without Flag Treated as Incomplete Setup**
  - Given: User `"user-ec2-legacy"` has an existing Firestore document that does NOT contain the `hasCompletedInterestsSetup` field (pre-feature document)
  - When: The app launches and `checkToken()` decodes the user document
  - Then: `hasCompletedInterestsSetup` decodes as `false` (the `UserModel` default), and `RootNavigationCoordinator` routes to `AppState.interestsSetup` — identical to a brand-new user
  - Verify: The `InterestsSelectionView` opens with no pre-selected chips; the route is `AppState.interestsSetup`; `HomeView` is NOT shown
