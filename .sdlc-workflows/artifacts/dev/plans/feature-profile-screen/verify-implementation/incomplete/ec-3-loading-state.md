# EC 3: Loading State

- [x] **Scenario: Full-screen loading dialog is shown while fetching user info**
  - Given: User "user-ec3-loading" is authenticated and ProfileView has just appeared
  - When: `viewModel.fetchUserInfo()` is in-flight and `viewModel.isLoading` is `true`
  - Then: A full-screen loading overlay is displayed, blocking interaction with the profile content underneath
  - Verify: `.showFullScreenDialog($viewModel.isLoading)` activates and the loading dialog is visually centered and covers the entire screen

- [ ] **Scenario: Loading state clears after successful data fetch** ❌ FAILED
  - Given: User "user-ec3-loaded" is authenticated and `viewModel.isLoading` transitions from `true` to `false`
  - When: `fetchUserInfo()` completes successfully
  - Then: The loading overlay dismisses and the profile info rows are fully visible with the user's data
  - Verify: `viewModel.isLoading` is `false` and no residual loading UI remains on screen
  - **Failure**: Loading state clears correctly, but the profile info rows are not displayed according to UI requirements — label and value are vertically stacked instead of horizontally arranged, and the value is enclosed in a rectangle.
  - **Root Cause**:
    1. `profileInfoRow` uses a `VStack` placing the label above the value. The requirement (per USER_INPUT) specifies label on the left and value on the right (an `HStack` layout).
    2. The value `Text` has a `.background { RoundedRectangle(cornerRadius: 15).fill(.lightYellow) }` applied, enclosing it in a visible rounded rectangle. The requirement states each row must not be enclosed by a rectangle.
  - **Affected Files**:
    - `Wishie/Screens/Profile/ProfileView.swift` — `profileInfoRow(label:value:)` function (lines 75–92): uses `VStack` and applies `RoundedRectangle` background to the value text.
