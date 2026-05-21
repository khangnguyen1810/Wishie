# EC 4: Error State

- [ ] **Scenario: Error message is displayed when getUserInfo() throws** ❌ FAILED
  - Given: User "user-ec4-error" is authenticated but the Firebase call inside `getUserInfo()` throws a network error
  - When: `viewModel.fetchUserInfo()` catches the error and sets `viewModel.errorMessage`
  - Then: The error message text is visible on screen, styled in the app's error color (`.wishiePink`), and the profile info rows display their empty/fallback values
  - Verify: `viewModel.errorMessage` is non-empty; the error `Text` view is rendered between the avatar and the info rows; the loading overlay is dismissed
  - **Failure**: Profile info rows do not display with the required layout — label should be on the left and value on the right (horizontal), but `profileInfoRow` uses a `VStack` (label on top, value below). Additionally, each row's value is wrapped in a `RoundedRectangle` background, which the UI requirement explicitly prohibits.
  - **Root Cause**: `profileInfoRow` uses `VStack(alignment: .leading, spacing: 10)` placing label above value, and applies `.background { RoundedRectangle(cornerRadius: 15).fill(.lightYellow).frame(height: 56) }` on the value `Text`. The correct layout is an `HStack` with the label on the leading side and value on the trailing side, with no enclosing rectangle.
  - **Affected Files**: [Wishie/Screens/Profile/ProfileView.swift](../../../../../Wishie/Screens/Profile/ProfileView.swift) — `profileInfoRow` function (lines 80–98)

- [x] **Scenario: Error message is cleared on successful re-fetch**
  - Given: User "user-ec4-retry" previously had an error (`viewModel.errorMessage` was non-empty) and the screen re-fetches successfully
  - When: `fetchUserInfo()` runs again and succeeds
  - Then: `viewModel.errorMessage` is reset to `""` and no error text is visible on screen
  - Verify: `errorMessage = ""` is set at the start of `fetchUserInfo()`; the error `Text` view is conditionally hidden
