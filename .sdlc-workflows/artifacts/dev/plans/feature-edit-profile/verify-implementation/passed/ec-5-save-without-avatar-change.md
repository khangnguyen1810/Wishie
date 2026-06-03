# EC 5: Save Without Avatar Change

- [x] **Scenario: Profile fields updated without selecting a new avatar**
  - Given: user 'user-ec5-no-avatar' has an existing `avatarUrl` in Firestore and edits only the phone field in `EditProfileView`
  - When: the user taps Save
  - Then: no avatar upload is performed; only the changed profile fields are written to Firestore; the existing `avatarUrl` is preserved in the document
  - Verify: Supabase Storage upload is NOT called; Firestore document retains the original `avatarUrl`; `ProfileView` continues to display the previous avatar image

