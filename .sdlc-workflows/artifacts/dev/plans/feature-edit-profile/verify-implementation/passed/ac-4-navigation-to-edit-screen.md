# AC 4: Navigation to Edit Screen

- [x] **Scenario: EditProfileView is accessible from ProfileView via the navigation coordinator**
  - Given: An authenticated user `user-ac4-nav` is on `ProfileView`
  - When: The user taps the edit action
  - Then: `EditProfileView` is pushed onto the navigation stack via the existing `RootNavigationCoordinator`
  - Verify: The back navigation returns the user to `ProfileView`; no other screens are affected

