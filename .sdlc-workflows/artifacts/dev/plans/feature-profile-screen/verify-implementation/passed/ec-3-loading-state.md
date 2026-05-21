# EC 3: Loading State

- [x] **Scenario: Full-screen loading dialog is shown while fetching user info**
  - Given: User "user-ec3-loading" is authenticated and ProfileView has just appeared
  - When: `viewModel.fetchUserInfo()` is in-flight and `viewModel.isLoading` is `true`
  - Then: A full-screen loading overlay is displayed, blocking interaction with the profile content underneath
  - Verify: `.showFullScreenDialog($viewModel.isLoading)` activates and the loading dialog is visually centered and covers the entire screen

- [x] **Scenario: Loading state clears after successful data fetch** ✅ RESOLVED
  - Given: User "user-ec3-loaded" is authenticated and `viewModel.isLoading` transitions from `true` to `false`
  - When: `fetchUserInfo()` completes successfully
  - Then: The loading overlay dismisses and the profile info rows are fully visible with the user's data
  - Verify: `viewModel.isLoading` is `false` and no residual loading UI remains on screen
  - **Resolution**:
    1. Replaced `VStack` with `HStack(spacing: 16)` in `profileInfoRow` — label is now on the left with `minWidth: 110` and value is on the right taking remaining space via `maxWidth: .infinity`.
    2. Removed the `.background { RoundedRectangle(cornerRadius: 15).fill(.lightYellow) }` modifier from the value `Text` — rows are no longer enclosed in a rectangle.
  - **Fixed Files**:
    - `Wishie/Screens/Profile/ProfileView.swift` — `profileInfoRow(label:value:)` updated to use `HStack` layout with no background rectangle.

