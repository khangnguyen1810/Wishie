# EC 6: ProfileView Data Refresh After Save

- [x] **Scenario: ProfileView reflects updated fields immediately after successful save**
  - Given: user 'user-ec6-refresh' has changed firstName from "Old" to "New Name" and dateOfBirth to a new date in `EditProfileView`
  - When: the save completes successfully and the user is navigated back to `ProfileView`
  - Then: `ProfileView` displays "New Name" and the updated date of birth without requiring a manual refresh or app restart
  - Verify: `ProfileViewModel` re-fetches or updates its local `UserModel` after a successful save; the displayed values in the profile row list match the values that were just submitted

- [x] **Scenario: ProfileView avatar updates immediately after first-time upload**
  - Given: user 'user-ec6-first-avatar' had no previous avatar (`avatarUrl` was nil) and has just uploaded one for the first time
  - When: the save completes and the user returns to `ProfileView`
  - Then: the placeholder image is replaced by the newly uploaded avatar, displayed clearly at the correct size
  - Verify: `UserModel.avatarUrl` is non-nil after save; the avatar image view loads from the URL and no placeholder fallback is visible

