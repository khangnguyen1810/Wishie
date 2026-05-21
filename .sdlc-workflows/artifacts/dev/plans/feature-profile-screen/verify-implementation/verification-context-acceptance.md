# Verification Context — Acceptance Scenarios

## Purpose

Define testable acceptance scenarios in Given/When/Then format to verify the implementation meets functional requirements and success criteria.
This document serves as the single source of truth for acceptance verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "user-ac1-login", "product-ac2-checkout"). No two scenarios should share mutable state.

## Acceptance Scenarios:

### AC 1: Profile Screen Entry Point

- [ ] **Scenario: Tapping the user avatar circle in HomeView presents ProfileView**
  - Given: A logged-in user named `user-ac1-entry` is on the Home screen with the top app bar visible
  - When: The user taps the circular user-avatar button (`Circle().fill(.lightYellow)`) in the top app bar
  - Then: `ProfileView` is presented as a sheet or modal on top of the Home screen
  - Verify: The screen title "Profile" is visible in the top app bar of the presented view; `BaseWishieScreen` is used as the root container

### AC 2: Top App Bar Layout

- [ ] **Scenario: Back button and title are correctly rendered in ProfileView's top bar**
  - Given: `ProfileView` is presented for user `user-ac2-topbar`
  - When: The screen finishes loading
  - Then: A back button (`back_icon` image inside a `lightYellow` circle) appears on the leading side of the top bar, and the title "Profile" is centered
  - Verify: Tapping the back button dismisses `ProfileView` and returns to the previous screen; the back button style matches other back buttons in the project

### AC 3: Avatar Display

- [ ] **Scenario: User avatar placeholder is prominently centered below the top bar**
  - Given: `ProfileView` is presented for user `user-ac3-avatar`
  - When: The screen content area is rendered
  - Then: A circular avatar (`Image("user")` inside a `lightYellow` circle, 100×100 pt) appears centered at the top of the scrollable content with visible padding from the top bar
  - Verify: The avatar is horizontally centered; there is at least 20 pt top padding; no real user photo is shown (placeholder only)

### AC 4: User Information Row Layout — Horizontal Label/Value

- [ ] **Scenario: Each profile info row displays label on the left and value on the right**
  - Given: `ProfileView` has successfully loaded data for user `user-ac4-layout` with full name "Khang Nguyen", date of birth "01/01/1995", email "khang@example.com", and phone "0901234567"
  - When: The user information section is displayed
  - Then: Each row renders as a single horizontal line with the label text (e.g., "Full Name") left-aligned and the corresponding value (e.g., "Khang Nguyen") right-aligned on the same line
  - Verify: The layout uses `HStack`; no `VStack` stacks label above value; label and value are on the same visual line

### AC 5: No Rectangle Enclosure on Info Rows

- [ ] **Scenario: Profile information rows are not enclosed in rectangular backgrounds**
  - Given: `ProfileView` has loaded user data for `user-ac5-norect`
  - When: The Full Name, Date of Birth, Email, and Phone rows are visible
  - Then: None of the four rows has a `RoundedRectangle` or any background shape surrounding the value or the entire row
  - Verify: Each row renders as plain text on the screen background; there is no filled rectangle (`lightYellow` or otherwise) wrapping any individual value

### AC 6: All Four User Fields Present and Readable

- [ ] **Scenario: All required user fields are displayed with correct data**
  - Given: `ProfileView` has fetched data for user `user-ac6-fields` with all four fields populated
  - When: The scrollable content area is fully rendered
  - Then: The labels "Full Name", "Date of Birth", "Email", and "Phone" are each visible with their corresponding values displayed to the right
  - Verify: All four rows are present; values are not empty strings or raw placeholders; "Date of Birth" value is formatted as a human-readable short date string (e.g., "Jan 1, 1995")

### AC 7: Row Spacing and Visual Clarity

- [ ] **Scenario: Adequate spacing between profile info rows ensures clear readability**
  - Given: `ProfileView` has loaded all four fields for user `user-ac7-spacing`
  - When: The user information section is displayed
  - Then: Each row is visually separated from adjacent rows with consistent spacing; rows do not appear cramped or overlapping
  - Verify: A vertical gap is present between each info row (minimum 12 pt recommended); the label and value within each row have a visible horizontal gap; the overall layout does not feel cluttered

### AC 8: Loading State During Data Fetch

- [ ] **Scenario: A loading indicator is shown while user data is being fetched**
  - Given: `ProfileView` is presented for user `user-ac8-loading` and the `fetchUserInfo()` call is in progress
  - When: The `.task` modifier triggers `viewModel.fetchUserInfo()` on appearance
  - Then: A full-screen loading dialog (`showFullScreenDialog`) is displayed, blocking interaction until data is returned
  - Verify: `viewModel.isLoading` is `true` during the fetch; the loading overlay disappears once `fetchUserInfo()` completes (success or failure)

### AC 9: Error State When Data Fetch Fails

- [ ] **Scenario: An error message is displayed if user data cannot be fetched**
  - Given: `ProfileView` is presented for user `user-ac9-error` and the `AuthenticateService.getUserInfo()` call throws an error
  - When: The fetch completes with a failure
  - Then: A non-empty error message is shown in `wishiePink` color within the content area; the loading overlay is dismissed
  - Verify: `viewModel.errorMessage` is not empty; the error text is visible and multiline-safe; the user can still tap the Logout button

### AC 10: Logout Button Triggers Sign-Out

- [ ] **Scenario: Tapping the Logout button signs the user out**
  - Given: `ProfileView` is presented for authenticated user `user-ac10-logout`
  - When: The user taps the "Log out" `WishieButton` at the bottom of the screen
  - Then: `authViewModel.logOut()` is called, and the app navigates away from the authenticated flow (e.g., back to the Welcome or Sign-In screen)
  - Verify: The Logout button uses `wishiePink` fill and white title text; it is positioned at the bottom of the screen with at least 20 pt bottom padding; the button is always enabled regardless of loading state
