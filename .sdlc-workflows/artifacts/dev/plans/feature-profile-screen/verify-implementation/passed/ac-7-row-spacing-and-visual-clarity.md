# AC 7: Row Spacing and Visual Clarity

- [x] **Scenario: Adequate spacing between profile info rows ensures clear readability** ✅ RESOLVED
  - Given: `ProfileView` has loaded all four fields for user `user-ac7-spacing`
  - When: The user information section is displayed
  - Then: Each row is visually separated from adjacent rows with consistent spacing; rows do not appear cramped or overlapping
  - Verify: A vertical gap is present between each info row (minimum 12 pt recommended); the label and value within each row have a visible horizontal gap; the overall layout does not feel cluttered
  - **Resolution**:
    1. Replaced `VStack(alignment: .leading, spacing: 10)` with `HStack(spacing: 16)` so the label is on the left and the value is on the right within the same horizontal row.
    2. Removed the `RoundedRectangle` `.background` modifier from the value `Text`; rows are now plain, non-enclosed lines.
    3. Row separation relies on the existing 24 pt `VStack` spacing in the parent, which exceeds the 12 pt minimum threshold.
  - **Affected Files**:
    - `Wishie/Screens/Profile/ProfileView.swift` — `profileInfoRow` helper: refactored to `HStack` layout without rectangle background.

