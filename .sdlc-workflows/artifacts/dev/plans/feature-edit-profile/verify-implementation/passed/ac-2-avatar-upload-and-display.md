# AC 2: Avatar Upload and Display

- [x] **Scenario: Selecting and uploading a new avatar persists the URL and displays the image in ProfileView**
  - Given: An authenticated user `user-ac2-avatar` with no existing avatar is on `EditProfileView`
  - When: The user taps the avatar picker, selects a photo from the device library via `PhotosPicker`, and taps Save
  - Then: The selected image is compressed to JPEG at 0.8 quality, uploaded to Supabase Storage at path `avatar/{userId}.jpg` with `upsert: true`, and the returned public URL is persisted in Firestore `users/{userId}`; `ProfileView` displays the uploaded avatar image
  - Verify: The avatar image renders clearly and without distortion in `ProfileView`; no placeholder is shown after a successful upload

- [x] **Scenario: Avatar placeholder is shown when no avatar URL exists**
  - Given: An authenticated user `user-ac2-noavatar` whose Firestore document has no `avatarUrl` value is viewing `ProfileView`
  - When: `ProfileView` loads
  - Then: The existing placeholder image is displayed instead of a broken image or empty space
  - Verify: Placeholder is visible and correctly sized with no layout breakage

- [x] **Scenario: Re-uploading an avatar replaces the previous image**
  - Given: An authenticated user `user-ac2-replace` already has an avatar URL stored (path `avatar/{userId}.jpg`)
  - When: The user opens `EditProfileView`, selects a different photo, and taps Save
  - Then: The new image is uploaded to the same path with `upsert: true`, overwriting the old file; the Firestore `avatarUrl` is updated to the new public URL; `ProfileView` displays the new avatar image clearly
  - Verify: The previous avatar is no longer shown; the updated image renders at the expected resolution and clarity

