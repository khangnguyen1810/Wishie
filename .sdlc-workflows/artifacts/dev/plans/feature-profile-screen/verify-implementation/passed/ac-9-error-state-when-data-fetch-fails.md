# AC 9: Error State When Data Fetch Fails

- [x] **Scenario: An error message is displayed if user data cannot be fetched** ✅ RESOLVED
  - Given: `ProfileView` is presented for user `user-ac9-error` and the `AuthenticateService.getUserInfo()` call throws an error
  - When: The fetch completes with a failure
  - Then: A non-empty error message is shown in `wishiePink` color within the content area; the loading overlay is dismissed
  - Verify: `viewModel.errorMessage` is not empty; the error text is visible and multiline-safe; the user can still tap the Logout button
  - **Failure 1**: Profile info rows use a vertical layout (label on top, value below) instead of the required horizontal layout (label on the left, value on the right)
  - **Root Cause 1**: `profileInfoRow` uses `VStack(alignment: .leading, spacing: 10)` for label and value. It must be changed to an `HStack` with label on the leading side and value on the trailing side.
  - **Affected Files 1**: [Wishie/Screens/Profile/ProfileView.swift](Wishie/Screens/Profile/ProfileView.swift) — `profileInfoRow` function, the `VStack` wrapping `Text(label)` and `Text(value)`
  - ✅ RESOLVED: Replaced `VStack(alignment: .leading, spacing: 10)` with `HStack(spacing: 16)`. Label is fixed-width on the leading side (`frame(minWidth: 110, alignment: .leading)`) and value fills remaining space on the trailing side (`frame(maxWidth: .infinity, alignment: .leading)`).
  - **Failure 2**: The value text in each profile info row is wrapped in a `RoundedRectangle` background, visually enclosing the value in a rectangle. The requirement states each line must not be enclosed by a rectangle.
  - **Root Cause 2**: `profileInfoRow` applies a `.background { RoundedRectangle(cornerRadius: 15).fill(.lightYellow).frame(height: 56) }` modifier to the value `Text`, creating a visible rectangular container around the value.
  - **Affected Files 2**: [Wishie/Screens/Profile/ProfileView.swift](Wishie/Screens/Profile/ProfileView.swift) — `profileInfoRow` function, the `.background` modifier on the value `Text`
  - ✅ RESOLVED: Removed the `.background { RoundedRectangle(cornerRadius: 15).fill(.lightYellow).frame(height: 56) }` and `.padding(.horizontal, 15)` modifiers from the value `Text`. Row padding is now applied uniformly via `.padding(.horizontal, 16)` on the `HStack`.

