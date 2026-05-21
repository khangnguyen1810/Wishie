# AC 4: User Information Row Layout — Horizontal Label/Value

- [x] **Scenario: Each profile info row displays label on the left and value on the right** ✅ RESOLVED
  - Given: `ProfileView` has successfully loaded data for user `user-ac4-layout` with full name "Khang Nguyen", date of birth "01/01/1995", email "khang@example.com", and phone "0901234567"
  - When: The user information section is displayed
  - Then: Each row renders as a single horizontal line with the label text (e.g., "Full Name") left-aligned and the corresponding value (e.g., "Khang Nguyen") right-aligned on the same line
  - Verify: The layout uses `HStack`; no `VStack` stacks label above value; label and value are on the same visual line
  - **Resolution**: Updated `profileInfoRow` to use `HStack(alignment: .center)` with `Spacer()` between label and value — label is left-aligned, value is right-aligned via `.multilineTextAlignment(.trailing)`. Removed the `RoundedRectangle` background from the value. Added `.padding(.vertical, 14)` inside the row and a `Divider()` at the bottom for clear visual separation. Wrapped all four `profileInfoRow` calls in a `VStack(spacing: 0)` in the body so the Dividers provide spacing without the extra 24pt gap from the parent `VStack(spacing: 24)`.
  - **Affected Files**: [Wishie/Screens/Profile/ProfileView.swift](../../../../../Wishie/Screens/Profile/ProfileView.swift)
