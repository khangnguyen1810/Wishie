# EC 4: Error State

- [x] **Scenario: Error message is displayed when getUserInfo() throws** ✅ RESOLVED
  - Given: User "user-ec4-error" is authenticated but the Firebase call inside `getUserInfo()` throws a network error
  - When: `viewModel.fetchUserInfo()` catches the error and sets `viewModel.errorMessage`
  - Then: The error message text is visible on screen, styled in the app's error color (`.wishiePink`), and the profile info rows display their empty/fallback values
  - Verify: `viewModel.errorMessage` is non-empty; the error `Text` view is rendered between the avatar and the info rows; the loading overlay is dismissed
  - **Resolution**: Replaced `VStack(alignment: .leading, spacing: 10)` with `HStack(spacing: 16)` so the label appears on the leading side and the value on the trailing side. Removed the `.background { RoundedRectangle(cornerRadius: 15).fill(.lightYellow).frame(height: 56) }` modifier from the value `Text`. The label uses `.frame(minWidth: 110, alignment: .leading)` and the value uses `.frame(maxWidth: .infinity, alignment: .leading)`. Parent `VStack(spacing: 24)` with `.padding(.horizontal, 16)` ensures clear visual separation between rows. No enclosing rectangle is present.
  - **Affected Files**: [Wishie/Screens/Profile/ProfileView.swift](../../../../../Wishie/Screens/Profile/ProfileView.swift) — `profileInfoRow` function

- [x] **Scenario: Error message is cleared on successful re-fetch**
  - Given: User "user-ec4-retry" previously had an error (`viewModel.errorMessage` was non-empty) and the screen re-fetches successfully
  - When: `fetchUserInfo()` runs again and succeeds
  - Then: `viewModel.errorMessage` is reset to `""` and no error text is visible on screen
  - Verify: `errorMessage = ""` is set at the start of `fetchUserInfo()`; the error `Text` view is conditionally hidden

