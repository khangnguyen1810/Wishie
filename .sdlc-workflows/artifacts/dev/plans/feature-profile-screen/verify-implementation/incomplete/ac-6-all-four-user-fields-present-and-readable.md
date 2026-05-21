# AC 6: All Four User Fields Present and Readable

- [ ] **Scenario: All required user fields are displayed with correct data** ❌ FAILED
  - Given: `ProfileView` has fetched data for user `user-ac6-fields` with all four fields populated
  - When: The scrollable content area is fully rendered
  - Then: The labels "Full Name", "Date of Birth", "Email", and "Phone" are each visible with their corresponding values displayed to the right
  - Verify: All four rows are present; values are not empty strings or raw placeholders; "Date of Birth" value is formatted as a human-readable short date string (e.g., "Jan 1, 1995")
  - **Failure 1 – Label and value are not displayed side-by-side (left/right)**
    - **Expected Behavior**: Each profile row should display the label on the left (e.g., "Full Name") and the value on the right (e.g., "Khang Nguyen") within the same horizontal line.
    - **Actual Behavior**: `profileInfoRow` uses a `VStack(alignment: .leading, spacing: 10)` which stacks the label _above_ the value vertically — not in a left-right `HStack` layout.
    - **Root Cause**: The layout container is `VStack` instead of `HStack`. The `Text(label)` and `Text(value)` elements are vertically stacked, violating the label-left / value-right requirement.
    - **Affected Files**: [Wishie/Screens/Profile/ProfileView.swift](Wishie/Screens/Profile/ProfileView.swift) — `profileInfoRow` function, lines 75–93
    - **Code Snippet**:
      ```swift
      VStack(alignment: .leading, spacing: 10) {
          Text(label) // stacked above, not to the left
          Text(value.isEmpty ? "-" : value) // stacked below, not to the right
      }
      ```
  - **Failure 2 – Value text is enclosed in a RoundedRectangle background**
    - **Expected Behavior**: Each row should not be enclosed by a rectangle; the layout should be clean with clear spacing only.
    - **Actual Behavior**: The value `Text` has a `.background { RoundedRectangle(cornerRadius: 15).fill(.lightYellow).frame(height: 56) }` applied, visually wrapping the value inside a rounded rectangle box.
    - **Root Cause**: The `.background` modifier with a `RoundedRectangle` is attached directly to the value `Text`, creating a card/box appearance that was explicitly excluded by the UI requirement.
    - **Affected Files**: [Wishie/Screens/Profile/ProfileView.swift](Wishie/Screens/Profile/ProfileView.swift) — `profileInfoRow` function, lines 87–91
    - **Code Snippet**:
      ```swift
      Text(value.isEmpty ? "-" : value)
          .padding(.horizontal, 15)
          .background {
              RoundedRectangle(cornerRadius: 15)
                  .fill(.lightYellow)
                  .frame(height: 56)
          }
      ```
