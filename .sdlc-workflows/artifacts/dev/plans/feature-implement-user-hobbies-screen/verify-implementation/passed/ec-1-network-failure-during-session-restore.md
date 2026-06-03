# EC 1: Network Failure During Session Restore

- [x] **Scenario: Firestore Unavailable During checkToken Defaults to interestsSetup Routing**
  - Given: User `"user-ec1-offline"` is authenticated but Firestore is unreachable when `checkToken()` attempts to fetch `hasCompletedInterestsSetup`
  - When: The app launches and `checkToken()` completes with a network error, causing `getUserInfo()` to resolve with the default `UserModel`
  - Then: `hasCompletedInterestsSetup` defaults to `false`, `RootNavigationCoordinator` routes the app to `AppState.interestsSetup`, and the user lands on `InterestsSelectionView` in onboarding mode
  - Verify: The coordinator state is `AppState.interestsSetup`; `HomeView` is NOT displayed; `InterestsSelectionView` has no back button and no swipe-dismiss gesture

