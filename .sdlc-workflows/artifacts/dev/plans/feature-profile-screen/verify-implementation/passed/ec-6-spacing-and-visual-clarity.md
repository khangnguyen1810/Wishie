# EC 6: Spacing and Visual Clarity

- [x] **Scenario: Spacing between profile info rows is consistent and clearly separates each row** ✅ RESOLVED
  - Given: User "user-ec6-spacing" is authenticated and all four profile fields are populated
  - When: ProfileView is rendered with all four rows (Full Name, Date of Birth, Email, Phone)
  - Then: Each row is visually separated with consistent vertical spacing; no two rows appear merged or touching
  - Verify: The outer `VStack` uses a uniform `spacing` value (e.g., `spacing: 16` or greater); rows are distinguishable without requiring a divider or rectangle
  - **Failure**:
    1. The `profileInfoRow` layout uses a `VStack` (label stacked above value), not an `HStack` with label on the left and value on the right as required by the user specification. The profile info line should read "Full Name — Khang Nguyen" in a single horizontal row, not two stacked lines.
    2. The value `Text` is wrapped with a `RoundedRectangle(cornerRadius: 15).fill(.lightYellow)` background — this encloses each value in a visible rectangle box, directly violating the requirement "Each line should not be enclosed by a rectangle."
  - **Root Cause**: `profileInfoRow` was implemented as a `VStack` with a card-style background on the value text instead of a flat `HStack` row with no background decoration.
  - **Affected Files**: [ProfileView.swift](../../../../../Wishie/Screens/Profile/ProfileView.swift) — `profileInfoRow` function (lines 74–91): the `VStack` layout and `.background { RoundedRectangle(...) }` modifier on the value `Text`.
  - **Resolution**: Replaced `profileInfoRow` implementation from a `VStack` with card-style background to a flat `HStack(alignment: .center)` with `Spacer()` between label and value. Removed `RoundedRectangle` background entirely. The four rows are now direct children of the outer `VStack(spacing: 24)`, providing 24pt of consistent vertical spacing between each row.

- [x] **Scenario: Horizontal padding is applied so rows do not touch screen edges** ✅ RESOLVED
  - Given: User "user-ec6-padding" is authenticated and profile rows are rendered
  - When: Rows are displayed in horizontal label-value layout
  - Then: There is visible horizontal padding on both sides of each row so labels and values do not bleed to the device edge
  - Verify: `.padding(.horizontal, ...)` is applied to the rows container or to each `HStack` row
  - **Failure**: The outer `VStack(spacing: 24)` containing all four profile rows has only `.padding(.vertical, 10)` applied — no `.padding(.horizontal, ...)` is present on it. Each `profileInfoRow` VStack also has no outer horizontal padding. The `.padding(.horizontal, 15)` on the value `Text` is an inner padding inside the `RoundedRectangle` background, not an edge-guard for the row itself. As a result, the label text (`Text(label)` with `.frame(maxWidth: .infinity, alignment: .leading)`) extends to the screen edge with no horizontal inset.
  - **Root Cause**: Horizontal padding was omitted from the outer `VStack` or the `profileInfoRow` container.
  - **Affected Files**: [ProfileView.swift](../../../../../Wishie/Screens/Profile/ProfileView.swift) — `ScrollView > VStack` block (line 30): `.padding(.vertical, 10)` is the only padding modifier; no `.padding(.horizontal, ...)` is applied.
  - **Resolution**: Added `.padding(.horizontal, 16)` directly to the `HStack` inside `profileInfoRow`, ensuring each row has 16pt inset from screen edges without double-padding from the outer `VStack`.
