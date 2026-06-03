# EC 3: Network Failures During Save

- [x] **Scenario: Supabase Storage upload failure surfaces error to user**
  - Given: user 'user-ec3-upload-fail' has selected a new avatar and the device has a network connection that drops during the upload
  - When: the avatar upload to `avatar/{userId}.jpg` fails with a network error
  - Then: the error is caught, `ProfileViewModel.errorMessage` is set to a localised error string, the loading overlay is dismissed, and no Firestore write is attempted
  - Verify: error message is visible in the UI; Firestore `users/{userId}` document is NOT modified; the save button is re-enabled

- [x] **Scenario: Firestore write failure after successful avatar upload surfaces error**
  - Given: user 'user-ec3-firestore-fail' has successfully uploaded an avatar to Supabase Storage but the subsequent Firestore `users/{userId}` write fails
  - When: the Firestore update call returns an error
  - Then: `ProfileViewModel.errorMessage` is set to a localised error string and the loading overlay is dismissed
  - Verify: the error message is visible; the UI does NOT navigate back to `ProfileView` as if the save succeeded; the avatar URL may be orphaned in storage but no corrupt state is shown to the user

