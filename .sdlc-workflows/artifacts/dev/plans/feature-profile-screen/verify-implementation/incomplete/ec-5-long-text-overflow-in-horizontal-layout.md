# EC 5: Long Text Overflow in Horizontal Layout

- [ ] **Scenario: Very long email address does not overflow or truncate label** ❌ FAILED
  - Given: User "user-ec5-longemail" has an email address of 60+ characters (e.g., `"verylongemailaddressexample123456789@subdomain.example.com"`)
  - When: ProfileView loads and the Email row is rendered in horizontal layout
  - Then: The label "Email" remains fully visible on the leading side; the email value truncates gracefully (e.g., with ellipsis) on the trailing side without pushing the label off screen
  - Verify: The `HStack` layout constrains the value `Text` with `.lineLimit(1)` or truncation; the label always has a fixed or minimum width
  - **Failure**: The implementation uses `VStack` (label above, value below), not `HStack` (label left, value right). No `.lineLimit(1)` or `.truncationMode` is applied to the email value `Text`. The label has no fixed or minimum width. Additionally, the value is enclosed in a `RoundedRectangle` background, which violates the requirement that rows should not be enclosed by a rectangle.
  - **Root Cause**: `profileInfoRow` stacks label and value vertically via `VStack` instead of horizontally via `HStack`. The value `Text` view has no line limit or truncation modifier, so a 60+ character email would expand freely rather than truncate with an ellipsis. The `RoundedRectangle` background with `.frame(height: 56)` encloses the value, contrary to the design expectation.
  - **Affected Files**: [ProfileView.swift](../../../../../Wishie/Screens/Profile/ProfileView.swift) — `profileInfoRow` function (lines 75–91)

- [ ] **Scenario: Full name with a very long first or last name wraps or truncates correctly** ❌ FAILED
  - Given: User "user-ec5-longname" has `firstName` = `"Alexandros-Konstantinos"` and `lastName` = `"Papadimitriou-Stavropoulos"`
  - When: ProfileView loads and the Full Name row is rendered
  - Then: The Full Name value does not overflow the screen or overlap the label; text either wraps to a second line or truncates with ellipsis
  - Verify: The value `Text` view has appropriate `lineLimit` or `truncationMode` applied so the row remains readable
  - **Failure**: No `.lineLimit()` or `.truncationMode()` modifier is applied to the Full Name value `Text`. The `RoundedRectangle` background has a fixed `.frame(height: 56)`, meaning the background box will not expand if the text wraps to a second line — the wrapped text would visually overflow the rectangle. The layout is also `VStack` (label above, value below) rather than the expected horizontal arrangement (label left, value right), and the value is enclosed by a rectangle contrary to requirements.
  - **Root Cause**: `profileInfoRow` applies no text overflow control on the value `Text`. The background `RoundedRectangle` uses a fixed height of 56 pt (`.frame(height: 56)`), which does not grow with multi-line text. A compound name like `"Alexandros-Konstantinos Papadimitriou-Stavropoulos"` would wrap onto multiple lines while the background rectangle remains at 56 pt, producing a broken visual layout.
  - **Affected Files**: [ProfileView.swift](../../../../../Wishie/Screens/Profile/ProfileView.swift) — `profileInfoRow` function (lines 75–91)
