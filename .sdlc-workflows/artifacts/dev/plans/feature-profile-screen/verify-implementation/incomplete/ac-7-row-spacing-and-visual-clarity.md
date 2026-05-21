# AC 7: Row Spacing and Visual Clarity

- [ ] **Scenario: Adequate spacing between profile info rows ensures clear readability** ❌ FAILED
  - Given: `ProfileView` has loaded all four fields for user `user-ac7-spacing`
  - When: The user information section is displayed
  - Then: Each row is visually separated from adjacent rows with consistent spacing; rows do not appear cramped or overlapping
  - Verify: A vertical gap is present between each info row (minimum 12 pt recommended); the label and value within each row have a visible horizontal gap; the overall layout does not feel cluttered
  - **Failure**:
    1. Label and value are stacked **vertically** (label on top, value below) using `VStack(alignment: .leading, spacing: 10)` — requirement expects label on the **left** and value on the **right** within the same horizontal row.
    2. The value `Text` is enclosed in a `RoundedRectangle(cornerRadius: 15).fill(.lightYellow).frame(height: 56)` background — requirement states each information line should **not** be enclosed by a rectangle.
    3. The vertical row spacing (24 pt) does pass the minimum 12 pt threshold, but the two structural violations above constitute an overall layout failure.
  - **Root Cause**:
    - `profileInfoRow` is implemented as a `VStack` instead of an `HStack`, so it cannot achieve the label-left / value-right horizontal layout.
    - A `RoundedRectangle` fill is applied as a `.background` modifier on the value `Text`, which visually encloses the value in a card/rectangle — contrary to the clean, non-enclosed line format required.
  - **Affected Files**:
    - `Wishie/Screens/Profile/ProfileView.swift` — `profileInfoRow` helper (lines ~75–93): uses `VStack` layout and adds `RoundedRectangle` background to value text.
