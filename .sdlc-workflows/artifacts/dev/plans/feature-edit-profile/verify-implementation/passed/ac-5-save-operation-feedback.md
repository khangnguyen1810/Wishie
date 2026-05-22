# AC 5: Save Operation Feedback

- [x] **Scenario: Loading overlay is shown while save is in progress**
  - Given: An authenticated user `user-ac5-loading` has made valid changes on `EditProfileView`
  - When: The user taps Save and the upload/Firestore write is in-flight
  - Then: The `showFullScreenDialog` loading overlay is visible and the Save button is disabled until the operation completes
  - Verify: The overlay disappears after the operation resolves (success or failure); the Save button is not tappable during the operation

- [x] **Scenario: Error message is displayed when save or upload fails**
  - Given: An authenticated user `user-ac5-error` is on `EditProfileView` with valid changes, and the network or Supabase Storage is unavailable
  - When: The user taps Save and the upload or Firestore write returns an error
  - Then: A localised error message is surfaced via `ProfileViewModel.errorMessage`; the loading overlay is dismissed; the user remains on `EditProfileView` to retry
  - Verify: The error message is non-empty and user-readable; Firestore data is not partially updated
