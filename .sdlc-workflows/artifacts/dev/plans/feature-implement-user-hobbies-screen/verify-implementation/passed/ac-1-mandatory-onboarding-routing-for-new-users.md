# AC 1: Mandatory Onboarding Routing for New Users

- [x] **Scenario: New user is routed to Interests Setup before HomeView after sign-up**
  - Given: a new user `user-ac1-signup` has just completed sign-up and their Firestore document does not contain `hasCompletedInterestsSetup`
  - When: `RootNavigationCoordinator` resolves the post-signup app state
  - Then: the coordinator transitions to `AppState.interestsSetup` and `InterestsSelectionView` is rendered with `isOnboarding: true` before any transition to `AppState.authenticated`
  - Verify: `AppState.authenticated` (HomeView) is NOT shown until `InterestsSelectionView` triggers the save action; confirm `RootNavigationCoordinator` holds `.interestsSetup` state

