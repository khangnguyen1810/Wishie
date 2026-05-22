# EC 7: Backward Compatibility

- [x] **Scenario: Existing users without avatarUrl do not break ProfileView**
  - Given: user 'user-ec7-legacy' was created before the `avatarUrl` field was added and has no `avatarUrl` value in Firestore
  - When: `ProfileView` is loaded for this user
  - Then: `UserModel.avatarUrl` defaults to nil or empty string; the existing placeholder image is shown; no crash or decoding error occurs
  - Verify: `UserModel` decodes successfully from a Firestore document that omits `avatarUrl`; the placeholder asset is rendered in the avatar position
