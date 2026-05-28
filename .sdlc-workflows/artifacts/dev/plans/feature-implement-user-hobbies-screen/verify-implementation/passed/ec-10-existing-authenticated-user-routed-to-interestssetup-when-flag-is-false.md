# EC 10: Existing Authenticated User Routed to interestsSetup When Flag is False

- [x] **Scenario: Logged-In User with hasCompletedInterestsSetup False Is Forced Through Setup on App Open**
  - Given: User `"user-ec10-existing-incomplete"` is already authenticated (valid session token) but has `hasCompletedInterestsSetup: false` in their Firestore document
  - When: The app launches and `checkToken()` successfully fetches the user document
  - Then: `RootNavigationCoordinator` reads `hasCompletedInterestsSetup = false` and routes to `AppState.interestsSetup`; `HomeView` is NOT presented; `InterestsSelectionView` opens in onboarding mode
  - Verify: Coordinator state is `AppState.interestsSetup`; `InterestsSelectionView` has no back button; chips are pre-selected if the user had previously saved a partial `interests` array

