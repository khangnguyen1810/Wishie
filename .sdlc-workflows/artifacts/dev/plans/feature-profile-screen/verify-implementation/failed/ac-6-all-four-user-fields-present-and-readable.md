# AC 6: All Four User Fields Present and Readable

- [x] **Scenario: All required user fields are displayed with correct data** ✅ RESOLVED
  - Given: `ProfileView` has fetched data for user `user-ac6-fields` with all four fields populated
  - When: The scrollable content area is fully rendered
  - Then: The labels "Full Name", "Date of Birth", "Email", and "Phone" are each visible with their corresponding values displayed to the right
  - Verify: All four rows are present; values are not empty strings or raw placeholders; "Date of Birth" value is formatted as a human-readable short date string (e.g., "Jan 1, 1995")
  - **Failure 1 – Label and value are not displayed side-by-side (left/right)**
    - ✅ RESOLVED: Replaced `VStack(alignment: .leading, spacing: 10)` with `HStack(spacing: 16)` in `profileInfoRow`. The label `Text` is now on the left (with `frame(minWidth: 110, alignment: .leading)`) and the value `Text` expands to fill the remaining space on the right (`frame(maxWidth: .infinity, alignment: .leading)`).
    - **Affected Files**: [Wishie/Screens/Profile/ProfileView.swift](Wishie/Screens/Profile/ProfileView.swift) — `profileInfoRow` function
  - **Failure 2 – Value text is enclosed in a RoundedRectangle background**
    - ✅ RESOLVED: Removed the `.padding(.horizontal, 15)` and `.background { RoundedRectangle(...) }` modifiers from the value `Text`. The row now has clean horizontal spacing via `.padding(.horizontal, 16)` on the `HStack` with no rectangle enclosure.
    - **Affected Files**: [Wishie/Screens/Profile/ProfileView.swift](Wishie/Screens/Profile/ProfileView.swift) — `profileInfoRow` function
