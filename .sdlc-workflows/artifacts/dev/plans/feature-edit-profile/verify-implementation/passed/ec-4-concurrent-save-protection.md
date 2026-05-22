# EC 4: Concurrent Save Protection

- [x] **Scenario: Rapid duplicate taps on Save button do not trigger multiple uploads**
  - Given: user 'user-ec4-double-tap' has valid data and a new avatar selected, and a save operation is already in progress
  - When: the user taps the Save button a second time before the first operation completes
  - Then: the second tap is ignored; only one upload and one Firestore write are performed
  - Verify: the Save button is disabled (or the loading overlay intercepts interaction) during the in-flight operation; Supabase Storage and Firestore receive exactly one request each

