# AC 3: Post-Save Profile View Reflection

- [x] **Scenario: ProfileView reflects all updated information immediately after a successful save**
  - Given: An authenticated user `user-ac3-reflect` with firstName "Bob" and avatar URL "https://example.com/old.jpg" is on `EditProfileView`
  - When: The user updates firstName to "Robert", selects a new avatar, and taps Save
  - Then: Upon returning to `ProfileView`, the displayed firstName is "Robert" and the displayed avatar is the newly uploaded image — not the old cached values
  - Verify: No manual refresh is required; the re-fetch happens automatically after save; all edited fields match what the user entered

