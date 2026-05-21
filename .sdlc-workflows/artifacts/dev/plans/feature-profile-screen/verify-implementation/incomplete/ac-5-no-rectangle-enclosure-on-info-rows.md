# AC 5: No Rectangle Enclosure on Info Rows

- [ ] **Scenario: Profile information rows are not enclosed in rectangular backgrounds** ❌ FAILED
  - Given: `ProfileView` has loaded user data for `user-ac5-norect`
  - When: The Full Name, Date of Birth, Email, and Phone rows are visible
  - Then: None of the four rows has a `RoundedRectangle` or any background shape surrounding the value or the entire row
  - Verify: Each row renders as plain text on the screen background; there is no filled rectangle (`lightYellow` or otherwise) wrapping any individual value
  - **Failure**: The value `Text` in every info row is wrapped by a `RoundedRectangle(cornerRadius: 15).fill(.lightYellow).frame(height: 56)` background shape, violating the requirement that rows render as plain text with no rectangular enclosure.
  - **Root Cause**: The `profileInfoRow` private helper in `ProfileView.swift` applies a `.background { RoundedRectangle ... }` modifier directly to the value `Text`, enclosing it in a filled `lightYellow` rectangle with 56 pt height. This background modifier must be removed so the value is displayed as unstyled text on the screen background.
  - **Affected Files**: `Wishie/Screens/Profile/ProfileView.swift` — `profileInfoRow` function (lines 80–95), specifically the `.padding(.horizontal, 15)` + `.background { RoundedRectangle(cornerRadius: 15).fill(.lightYellow).frame(height: 56) }` modifiers on the value `Text`.
