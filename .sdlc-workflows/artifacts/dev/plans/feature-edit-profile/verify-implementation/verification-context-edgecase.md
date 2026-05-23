# Verification Context — Edge Case Scenarios

## Purpose

Define testable edge case scenarios in Given/When/Then format to verify the implementation handles boundary conditions, error states, and non-functional requirements.
This document serves as the single source of truth for edge case verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "cart-ec1-empty", "user-ec2-locked"). No two scenarios should share mutable state.

## Edge Case Scenarios:

### EC 1: Empty Required Fields

- [ ] **Scenario: Save blocked when firstName is empty**
  - Given: user 'user-ec1-empty-first' has opened `EditProfileView` and cleared the firstName field entirely
  - When: the user taps the Save button
  - Then: the save operation does not proceed, no network calls are made, and an inline validation error is shown indicating firstName is required
  - Verify: `ProfileViewModel.errorMessage` is non-nil; Firestore write and Supabase upload are NOT invoked; the loading overlay does NOT appear

- [ ] **Scenario: Save blocked when lastName is empty**
  - Given: user 'user-ec1-empty-last' has opened `EditProfileView` and cleared the lastName field entirely while firstName is valid
  - When: the user taps the Save button
  - Then: the save operation does not proceed and a validation error is surfaced for lastName
  - Verify: `ProfileViewModel.errorMessage` is non-nil; no Firestore or Supabase calls are triggered

- [ ] **Scenario: Save blocked when both names contain only whitespace**
  - Given: user 'user-ec1-whitespace' has entered a single space character in both firstName and lastName fields
  - When: the user taps the Save button
  - Then: whitespace-only input is treated as invalid and the save is blocked with an error message
  - Verify: `ProfileViewModel.errorMessage` is non-nil; `.trimmingCharacters(in: .whitespaces)` on each field produces an empty string; no network calls are made

### EC 2: Avatar Image Compression and Quality

- [ ] **Scenario: Large avatar image is compressed before upload**
  - Given: user 'user-ec2-large-img' selects a photo from the library that is larger than 3 MB
  - When: the user taps Save
  - Then: the image is compressed to JPEG at 0.8 quality before being sent to Supabase Storage, reducing the upload payload
  - Verify: the data passed to the upload method is JPEG-encoded at 0.8 quality; upload payload is smaller than the original raw image data

- [ ] **Scenario: Avatar image is displayed clearly in ProfileView after upload**
  - Given: user 'user-ec2-avatar-display' has successfully uploaded a new avatar image and the returned public URL has been persisted in Firestore
  - When: the user returns to `ProfileView`
  - Then: the avatar image is fetched from the public URL and rendered at the correct display size without visible pixelation or distortion
  - Verify: the image view loads from the `avatarUrl` stored in `UserModel`; no placeholder is shown; the image fills the avatar frame at the intended resolution

### EC 3: Network Failures During Save

- [ ] **Scenario: Supabase Storage upload failure surfaces error to user**
  - Given: user 'user-ec3-upload-fail' has selected a new avatar and the device has a network connection that drops during the upload
  - When: the avatar upload to `avatar/{userId}.jpg` fails with a network error
  - Then: the error is caught, `ProfileViewModel.errorMessage` is set to a localised error string, the loading overlay is dismissed, and no Firestore write is attempted
  - Verify: error message is visible in the UI; Firestore `users/{userId}` document is NOT modified; the save button is re-enabled

- [ ] **Scenario: Firestore write failure after successful avatar upload surfaces error**
  - Given: user 'user-ec3-firestore-fail' has successfully uploaded an avatar to Supabase Storage but the subsequent Firestore `users/{userId}` write fails
  - When: the Firestore update call returns an error
  - Then: `ProfileViewModel.errorMessage` is set to a localised error string and the loading overlay is dismissed
  - Verify: the error message is visible; the UI does NOT navigate back to `ProfileView` as if the save succeeded; the avatar URL may be orphaned in storage but no corrupt state is shown to the user

### EC 4: Concurrent Save Protection

- [ ] **Scenario: Rapid duplicate taps on Save button do not trigger multiple uploads**
  - Given: user 'user-ec4-double-tap' has valid data and a new avatar selected, and a save operation is already in progress
  - When: the user taps the Save button a second time before the first operation completes
  - Then: the second tap is ignored; only one upload and one Firestore write are performed
  - Verify: the Save button is disabled (or the loading overlay intercepts interaction) during the in-flight operation; Supabase Storage and Firestore receive exactly one request each

### EC 5: Save Without Avatar Change

- [ ] **Scenario: Profile fields updated without selecting a new avatar**
  - Given: user 'user-ec5-no-avatar' has an existing `avatarUrl` in Firestore and edits only the phone field in `EditProfileView`
  - When: the user taps Save
  - Then: no avatar upload is performed; only the changed profile fields are written to Firestore; the existing `avatarUrl` is preserved in the document
  - Verify: Supabase Storage upload is NOT called; Firestore document retains the original `avatarUrl`; `ProfileView` continues to display the previous avatar image

### EC 6: ProfileView Data Refresh After Save

- [ ] **Scenario: ProfileView reflects updated fields immediately after successful save**
  - Given: user 'user-ec6-refresh' has changed firstName from "Old" to "New Name" and dateOfBirth to a new date in `EditProfileView`
  - When: the save completes successfully and the user is navigated back to `ProfileView`
  - Then: `ProfileView` displays "New Name" and the updated date of birth without requiring a manual refresh or app restart
  - Verify: `ProfileViewModel` re-fetches or updates its local `UserModel` after a successful save; the displayed values in the profile row list match the values that were just submitted

- [ ] **Scenario: ProfileView avatar updates immediately after first-time upload**
  - Given: user 'user-ec6-first-avatar' had no previous avatar (`avatarUrl` was nil) and has just uploaded one for the first time
  - When: the save completes and the user returns to `ProfileView`
  - Then: the placeholder image is replaced by the newly uploaded avatar, displayed clearly at the correct size
  - Verify: `UserModel.avatarUrl` is non-nil after save; the avatar image view loads from the URL and no placeholder fallback is visible

### EC 7: Backward Compatibility

- [ ] **Scenario: Existing users without avatarUrl do not break ProfileView**
  - Given: user 'user-ec7-legacy' was created before the `avatarUrl` field was added and has no `avatarUrl` value in Firestore
  - When: `ProfileView` is loaded for this user
  - Then: `UserModel.avatarUrl` defaults to nil or empty string; the existing placeholder image is shown; no crash or decoding error occurs
  - Verify: `UserModel` decodes successfully from a Firestore document that omits `avatarUrl`; the placeholder asset is rendered in the avatar position
