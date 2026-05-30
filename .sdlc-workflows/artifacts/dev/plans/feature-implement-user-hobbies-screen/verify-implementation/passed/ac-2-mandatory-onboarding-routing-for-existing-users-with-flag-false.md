# AC 2: Mandatory Onboarding Routing for Existing Users with Flag False

- [x] **Scenario: Existing user with `hasCompletedInterestsSetup = false` is routed to setup on app open**
  - Given: an authenticated user `user-ac2-legacy` has a Firestore document where `hasCompletedInterestsSetup` is `false` (or the field is absent)
  - When: the app restores the session by calling `checkToken()` and fetching user info
  - Then: `RootNavigationCoordinator` transitions to `AppState.interestsSetup`, showing `InterestsSelectionView` with `isOnboarding: true`
  - Verify: HomeView is not presented; the routing result is identical to the new-user post-signup flow

