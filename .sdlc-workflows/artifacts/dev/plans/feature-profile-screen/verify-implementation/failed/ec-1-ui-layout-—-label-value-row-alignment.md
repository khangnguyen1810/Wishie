# EC 1: UI Layout — Label-Value Row Alignment

- [x] **Scenario: Profile info row displays label on the left and value on the right** ✅ RESOLVED
  - Given: User "user-ec1-layout" is authenticated and their profile data has loaded successfully
  - When: The ProfileView is visible and the user info rows are rendered
  - Then: Each row (Full Name, Date of Birth, Email, Phone) renders as a horizontal layout with the label text on the left and the corresponding value on the right on the same line
  - Verify: Inspect `profileInfoRow` — it must use an `HStack` (not a `VStack`), with the label on the leading side and the value on the trailing side
  - **Failure**: `profileInfoRow` uses `VStack(alignment: .leading, spacing: 10)` — the label sits above the value vertically, not side-by-side horizontally. There is no `HStack` present.
  - **Root Cause**: The layout container is `VStack` instead of `HStack`, so label and value are stacked top-to-bottom rather than left-to-right on the same line.
  - **Affected Files**: [ProfileView.swift](../../../../../Wishie/Screens/Profile/ProfileView.swift) — `profileInfoRow` function, lines 76–91
  - **Resolution**: Replaced `VStack(alignment: .leading, spacing: 10)` with `HStack(spacing: 16)`. Label uses `.frame(minWidth: 110, alignment: .leading)` on the left; value uses `.frame(maxWidth: .infinity, alignment: .leading)` on the right.

- [x] **Scenario: Profile info row value is not enclosed in a rectangle** ✅ RESOLVED
  - Given: User "user-ec1-norect" is authenticated and their profile data has loaded successfully
  - When: The ProfileView is visible and the user info rows are rendered
  - Then: No row value is wrapped in a `RoundedRectangle`, card, or any filled background shape — values appear as plain text inline with labels
  - Verify: Confirm `profileInfoRow` contains no `.background` modifier with a `RoundedRectangle` or any shape fill on individual row values
  - **Failure**: The value `Text` view has a `.background` modifier containing `RoundedRectangle(cornerRadius: 15).fill(.lightYellow).frame(height: 56)`, which visually encloses each value in a filled rounded rectangle card.
  - **Root Cause**: A `.background { RoundedRectangle(...).fill(.lightYellow) }` modifier was applied directly to the value `Text`, contradicting the requirement that values appear as plain text without any enclosing shape.
  - **Affected Files**: [ProfileView.swift](../../../../../Wishie/Screens/Profile/ProfileView.swift) — `profileInfoRow` function, lines 83–90
  - **Resolution**: Removed the `.background { RoundedRectangle(cornerRadius: 15).fill(.lightYellow).frame(height: 56) }` modifier entirely. The value `Text` now renders as plain text with no enclosing shape.
