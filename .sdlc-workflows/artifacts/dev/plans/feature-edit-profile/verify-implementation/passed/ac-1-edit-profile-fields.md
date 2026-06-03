# AC 1: Edit Profile Fields

- [x] **Scenario: All editable fields can be modified and saved successfully**
  - Given: An authenticated user `user-ac1-edit` with existing profile data (firstName: "Alice", lastName: "Tran", phone: "0901000001", dateOfBirth: "01/01/1990") is on `ProfileView`
  - When: The user taps the edit button to navigate to `EditProfileView`, updates firstName to "Alicia", lastName to "Nguyen", phone to "0912345678", dateOfBirth to "15/06/1992", and taps Save
  - Then: The save operation completes without error, and `ProfileView` immediately re-fetches and displays firstName "Alicia", lastName "Nguyen", phone "0912345678", and dateOfBirth "15/06/1992"
  - Verify: All four updated field values are visible in `ProfileView` after the save; no stale data remains on screen

- [x] **Scenario: Empty firstName and lastName are rejected before save**
  - Given: An authenticated user `user-ac1-validate` is on `EditProfileView` with firstName and lastName fields cleared
  - When: The user taps Save with both firstName and lastName empty
  - Then: The save is blocked and a localised error message is surfaced via `ProfileViewModel.errorMessage`; no network call is made
  - Verify: `errorMessage` is non-empty and visible to the user; Firestore document is unchanged

- [x] **Scenario: Email field is read-only in the edit form**
  - Given: An authenticated user `user-ac1-email` with email "user-ac1@wishie.test" is on `EditProfileView`
  - When: The user attempts to interact with the email field
  - Then: The email field is non-editable and its value remains "user-ac1@wishie.test" throughout the session
  - Verify: No keyboard appears for the email field; the value displayed matches the authenticated account email

