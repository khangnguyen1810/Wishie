# AC 5: No Rectangle Enclosure on Info Rows

- [x] **Scenario: Profile information rows are not enclosed in rectangular backgrounds** ✅ RESOLVED
  - Given: `ProfileView` has loaded user data for `user-ac5-norect`
  - When: The Full Name, Date of Birth, Email, and Phone rows are visible
  - Then: None of the four rows has a `RoundedRectangle` or any background shape surrounding the value or the entire row
  - Verify: Each row renders as plain text on the screen background; there is no filled rectangle (`lightYellow` or otherwise) wrapping any individual value
  - **Resolution**: Replaced the vertical `VStack` layout (with `.background { RoundedRectangle(cornerRadius: 15).fill(.lightYellow).frame(height: 56) }` on the value `Text`) with a horizontal `HStack` layout — label on the left, value on the right via `Spacer()`, wrapped in a `VStack(spacing: 0)` with a `Divider()` at the bottom and `.padding(.vertical, 14)` for clear row spacing. No background shape or rectangle remains.
  - **Affected Files**: `Wishie/Screens/Profile/ProfileView.swift` — `profileInfoRow` function.

