# EC 2: Avatar Image Compression and Quality

- [x] **Scenario: Large avatar image is compressed before upload**
  - Given: user 'user-ec2-large-img' selects a photo from the library that is larger than 3 MB
  - When: the user taps Save
  - Then: the image is compressed to JPEG at 0.8 quality before being sent to Supabase Storage, reducing the upload payload
  - Verify: the data passed to the upload method is JPEG-encoded at 0.8 quality; upload payload is smaller than the original raw image data

- [x] **Scenario: Avatar image is displayed clearly in ProfileView after upload**
  - Given: user 'user-ec2-avatar-display' has successfully uploaded a new avatar image and the returned public URL has been persisted in Firestore
  - When: the user returns to `ProfileView`
  - Then: the avatar image is fetched from the public URL and rendered at the correct display size without visible pixelation or distortion
  - Verify: the image view loads from the `avatarUrl` stored in `UserModel`; no placeholder is shown; the image fills the avatar frame at the intended resolution

