# Verification Context — Edge Case Scenarios

## Purpose

Define testable edge case scenarios in Given/When/Then format to verify the implementation handles boundary conditions, error states, and non-functional requirements.
This document serves as the single source of truth for edge case verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "cart-ec1-empty", "user-ec2-locked"). No two scenarios should share mutable state.

## Edge Case Scenarios:

### EC 1: UI Layout — Label-Value Row Alignment

- [ ] **Scenario: Profile info row displays label on the left and value on the right**
  - Given: User "user-ec1-layout" is authenticated and their profile data has loaded successfully
  - When: The ProfileView is visible and the user info rows are rendered
  - Then: Each row (Full Name, Date of Birth, Email, Phone) renders as a horizontal layout with the label text on the left and the corresponding value on the right on the same line
  - Verify: Inspect `profileInfoRow` — it must use an `HStack` (not a `VStack`), with the label on the leading side and the value on the trailing side

- [ ] **Scenario: Profile info row value is not enclosed in a rectangle**
  - Given: User "user-ec1-norect" is authenticated and their profile data has loaded successfully
  - When: The ProfileView is visible and the user info rows are rendered
  - Then: No row value is wrapped in a `RoundedRectangle`, card, or any filled background shape — values appear as plain text inline with labels
  - Verify: Confirm `profileInfoRow` contains no `.background` modifier with a `RoundedRectangle` or any shape fill on individual row values

### EC 2: Empty / Partial User Data

- [ ] **Scenario: Profile row shows fallback dash when a string field is empty**
  - Given: User "user-ec2-emptyfields" has `phone` stored as an empty string `""` in Firebase
  - When: ProfileView loads and `viewModel.userInfo.phone` is `""`
  - Then: The Phone row displays `"-"` as the value instead of blank text
  - Verify: `profileInfoRow(label:value:)` renders `Text("-")` when value is empty; confirm `value.isEmpty ? "-" : value` logic handles this

- [ ] **Scenario: Full Name row shows fallback when both firstName and lastName are empty**
  - Given: User "user-ec2-noname" has both `firstName` and `lastName` as `""` in Firebase
  - When: ProfileView loads and `viewModel.userInfo.getFullName()` returns `" "` (a single space)
  - Then: The Full Name row does not display a single invisible space; it displays `"-"` as the fallback value
  - Verify: `getFullName()` result of `" "` must be treated as empty — consider trimming whitespace before the empty check in `profileInfoRow`

- [ ] **Scenario: Date of Birth defaults to current date for user with no DOB stored**
  - Given: User "user-ec2-nodob" has no `dateOfBirth` field in their Firebase document
  - When: `UserModel.init(dictionary:)` is called and no `dateOfBirth` Timestamp exists
  - Then: `dateOfBirth` defaults to `Date()` (today's date), and the Date of Birth row displays today's date formatted as a short date string rather than `"-"`
  - Verify: Confirm the fallback `Date()` is visible in the DOB row; decide whether this should display `"-"` instead and update `profileInfoRow` or `UserModel` accordingly

### EC 3: Loading State

- [ ] **Scenario: Full-screen loading dialog is shown while fetching user info**
  - Given: User "user-ec3-loading" is authenticated and ProfileView has just appeared
  - When: `viewModel.fetchUserInfo()` is in-flight and `viewModel.isLoading` is `true`
  - Then: A full-screen loading overlay is displayed, blocking interaction with the profile content underneath
  - Verify: `.showFullScreenDialog($viewModel.isLoading)` activates and the loading dialog is visually centered and covers the entire screen

- [ ] **Scenario: Loading state clears after successful data fetch**
  - Given: User "user-ec3-loaded" is authenticated and `viewModel.isLoading` transitions from `true` to `false`
  - When: `fetchUserInfo()` completes successfully
  - Then: The loading overlay dismisses and the profile info rows are fully visible with the user's data
  - Verify: `viewModel.isLoading` is `false` and no residual loading UI remains on screen

### EC 4: Error State

- [ ] **Scenario: Error message is displayed when getUserInfo() throws**
  - Given: User "user-ec4-error" is authenticated but the Firebase call inside `getUserInfo()` throws a network error
  - When: `viewModel.fetchUserInfo()` catches the error and sets `viewModel.errorMessage`
  - Then: The error message text is visible on screen, styled in the app's error color (`.wishiePink`), and the profile info rows display their empty/fallback values
  - Verify: `viewModel.errorMessage` is non-empty; the error `Text` view is rendered between the avatar and the info rows; the loading overlay is dismissed

- [ ] **Scenario: Error message is cleared on successful re-fetch**
  - Given: User "user-ec4-retry" previously had an error (`viewModel.errorMessage` was non-empty) and the screen re-fetches successfully
  - When: `fetchUserInfo()` runs again and succeeds
  - Then: `viewModel.errorMessage` is reset to `""` and no error text is visible on screen
  - Verify: `errorMessage = ""` is set at the start of `fetchUserInfo()`; the error `Text` view is conditionally hidden

### EC 5: Long Text Overflow in Horizontal Layout

- [ ] **Scenario: Very long email address does not overflow or truncate label**
  - Given: User "user-ec5-longemail" has an email address of 60+ characters (e.g., `"verylongemailaddressexample123456789@subdomain.example.com"`)
  - When: ProfileView loads and the Email row is rendered in horizontal layout
  - Then: The label "Email" remains fully visible on the leading side; the email value truncates gracefully (e.g., with ellipsis) on the trailing side without pushing the label off screen
  - Verify: The `HStack` layout constrains the value `Text` with `.lineLimit(1)` or truncation; the label always has a fixed or minimum width

- [ ] **Scenario: Full name with a very long first or last name wraps or truncates correctly**
  - Given: User "user-ec5-longname" has `firstName` = `"Alexandros-Konstantinos"` and `lastName` = `"Papadimitriou-Stavropoulos"`
  - When: ProfileView loads and the Full Name row is rendered
  - Then: The Full Name value does not overflow the screen or overlap the label; text either wraps to a second line or truncates with ellipsis
  - Verify: The value `Text` view has appropriate `lineLimit` or `truncationMode` applied so the row remains readable

### EC 6: Spacing and Visual Clarity

- [ ] **Scenario: Spacing between profile info rows is consistent and clearly separates each row**
  - Given: User "user-ec6-spacing" is authenticated and all four profile fields are populated
  - When: ProfileView is rendered with all four rows (Full Name, Date of Birth, Email, Phone)
  - Then: Each row is visually separated with consistent vertical spacing; no two rows appear merged or touching
  - Verify: The outer `VStack` uses a uniform `spacing` value (e.g., `spacing: 16` or greater); rows are distinguishable without requiring a divider or rectangle

- [ ] **Scenario: Horizontal padding is applied so rows do not touch screen edges**
  - Given: User "user-ec6-padding" is authenticated and profile rows are rendered
  - When: Rows are displayed in horizontal label-value layout
  - Then: There is visible horizontal padding on both sides of each row so labels and values do not bleed to the device edge
  - Verify: `.padding(.horizontal, ...)` is applied to the rows container or to each `HStack` row
