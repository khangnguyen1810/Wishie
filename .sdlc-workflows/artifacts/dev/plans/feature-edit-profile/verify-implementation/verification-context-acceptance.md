# Verification Context — Acceptance Scenarios

## Purpose

Define testable acceptance scenarios in Given/When/Then format to verify the implementation meets functional requirements and success criteria.
This document serves as the single source of truth for acceptance verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "user-ac1-login", "product-ac2-checkout"). No two scenarios should share mutable state.

## Acceptance Scenarios:

### AC 1: Edit Profile Fields

- [ ] **Scenario: All editable fields can be modified and saved successfully**
  - Given: An authenticated user `user-ac1-edit` with existing profile data (firstName: "Alice", lastName: "Tran", phone: "0901000001", dateOfBirth: "01/01/1990") is on `ProfileView`
  - When: The user taps the edit button to navigate to `EditProfileView`, updates firstName to "Alicia", lastName to "Nguyen", phone to "0912345678", dateOfBirth to "15/06/1992", and taps Save
  - Then: The save operation completes without error, and `ProfileView` immediately re-fetches and displays firstName "Alicia", lastName "Nguyen", phone "0912345678", and dateOfBirth "15/06/1992"
  - Verify: All four updated field values are visible in `ProfileView` after the save; no stale data remains on screen

- [ ] **Scenario: Empty firstName and lastName are rejected before save**
  - Given: An authenticated user `user-ac1-validate` is on `EditProfileView` with firstName and lastName fields cleared
  - When: The user taps Save with both firstName and lastName empty
  - Then: The save is blocked and a localised error message is surfaced via `ProfileViewModel.errorMessage`; no network call is made
  - Verify: `errorMessage` is non-empty and visible to the user; Firestore document is unchanged

- [ ] **Scenario: Email field is read-only in the edit form**
  - Given: An authenticated user `user-ac1-email` with email "user-ac1@wishie.test" is on `EditProfileView`
  - When: The user attempts to interact with the email field
  - Then: The email field is non-editable and its value remains "user-ac1@wishie.test" throughout the session
  - Verify: No keyboard appears for the email field; the value displayed matches the authenticated account email

### AC 2: Avatar Upload and Display

- [ ] **Scenario: Selecting and uploading a new avatar persists the URL and displays the image in ProfileView**
  - Given: An authenticated user `user-ac2-avatar` with no existing avatar is on `EditProfileView`
  - When: The user taps the avatar picker, selects a photo from the device library via `PhotosPicker`, and taps Save
  - Then: The selected image is compressed to JPEG at 0.8 quality, uploaded to Supabase Storage at path `avatar/{userId}.jpg` with `upsert: true`, and the returned public URL is persisted in Firestore `users/{userId}`; `ProfileView` displays the uploaded avatar image
  - Verify: The avatar image renders clearly and without distortion in `ProfileView`; no placeholder is shown after a successful upload

- [ ] **Scenario: Avatar placeholder is shown when no avatar URL exists**
  - Given: An authenticated user `user-ac2-noavatar` whose Firestore document has no `avatarUrl` value is viewing `ProfileView`
  - When: `ProfileView` loads
  - Then: The existing placeholder image is displayed instead of a broken image or empty space
  - Verify: Placeholder is visible and correctly sized with no layout breakage

- [ ] **Scenario: Re-uploading an avatar replaces the previous image**
  - Given: An authenticated user `user-ac2-replace` already has an avatar URL stored (path `avatar/{userId}.jpg`)
  - When: The user opens `EditProfileView`, selects a different photo, and taps Save
  - Then: The new image is uploaded to the same path with `upsert: true`, overwriting the old file; the Firestore `avatarUrl` is updated to the new public URL; `ProfileView` displays the new avatar image clearly
  - Verify: The previous avatar is no longer shown; the updated image renders at the expected resolution and clarity

### AC 3: Post-Save Profile View Reflection

- [ ] **Scenario: ProfileView reflects all updated information immediately after a successful save**
  - Given: An authenticated user `user-ac3-reflect` with firstName "Bob" and avatar URL "https://example.com/old.jpg" is on `EditProfileView`
  - When: The user updates firstName to "Robert", selects a new avatar, and taps Save
  - Then: Upon returning to `ProfileView`, the displayed firstName is "Robert" and the displayed avatar is the newly uploaded image — not the old cached values
  - Verify: No manual refresh is required; the re-fetch happens automatically after save; all edited fields match what the user entered

### AC 4: Navigation to Edit Screen

- [ ] **Scenario: EditProfileView is accessible from ProfileView via the navigation coordinator**
  - Given: An authenticated user `user-ac4-nav` is on `ProfileView`
  - When: The user taps the edit action
  - Then: `EditProfileView` is pushed onto the navigation stack via the existing `RootNavigationCoordinator`
  - Verify: The back navigation returns the user to `ProfileView`; no other screens are affected

### AC 5: Save Operation Feedback

- [ ] **Scenario: Loading overlay is shown while save is in progress**
  - Given: An authenticated user `user-ac5-loading` has made valid changes on `EditProfileView`
  - When: The user taps Save and the upload/Firestore write is in-flight
  - Then: The `showFullScreenDialog` loading overlay is visible and the Save button is disabled until the operation completes
  - Verify: The overlay disappears after the operation resolves (success or failure); the Save button is not tappable during the operation

- [ ] **Scenario: Error message is displayed when save or upload fails**
  - Given: An authenticated user `user-ac5-error` is on `EditProfileView` with valid changes, and the network or Supabase Storage is unavailable
  - When: The user taps Save and the upload or Firestore write returns an error
  - Then: A localised error message is surfaced via `ProfileViewModel.errorMessage`; the loading overlay is dismissed; the user remains on `EditProfileView` to retry
  - Verify: The error message is non-empty and user-readable; Firestore data is not partially updated
