# EC 1: Empty Required Fields

- [x] **Scenario: Save blocked when firstName is empty**
  - Given: user 'user-ec1-empty-first' has opened `EditProfileView` and cleared the firstName field entirely
  - When: the user taps the Save button
  - Then: the save operation does not proceed, no network calls are made, and an inline validation error is shown indicating firstName is required
  - Verify: `ProfileViewModel.errorMessage` is non-nil; Firestore write and Supabase upload are NOT invoked; the loading overlay does NOT appear

- [x] **Scenario: Save blocked when lastName is empty**
  - Given: user 'user-ec1-empty-last' has opened `EditProfileView` and cleared the lastName field entirely while firstName is valid
  - When: the user taps the Save button
  - Then: the save operation does not proceed and a validation error is surfaced for lastName
  - Verify: `ProfileViewModel.errorMessage` is non-nil; no Firestore or Supabase calls are triggered

- [x] **Scenario: Save blocked when both names contain only whitespace**
  - Given: user 'user-ec1-whitespace' has entered a single space character in both firstName and lastName fields
  - When: the user taps the Save button
  - Then: whitespace-only input is treated as invalid and the save is blocked with an error message
  - Verify: `ProfileViewModel.errorMessage` is non-nil; `.trimmingCharacters(in: .whitespaces)` on each field produces an empty string; no network calls are made

