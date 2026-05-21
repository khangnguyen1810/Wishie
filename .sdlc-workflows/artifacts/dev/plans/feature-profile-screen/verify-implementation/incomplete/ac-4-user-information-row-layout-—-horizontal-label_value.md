# AC 4: User Information Row Layout — Horizontal Label/Value

- [ ] **Scenario: Each profile info row displays label on the left and value on the right** ❌ FAILED
  - Given: `ProfileView` has successfully loaded data for user `user-ac4-layout` with full name "Khang Nguyen", date of birth "01/01/1995", email "khang@example.com", and phone "0901234567"
  - When: The user information section is displayed
  - Then: Each row renders as a single horizontal line with the label text (e.g., "Full Name") left-aligned and the corresponding value (e.g., "Khang Nguyen") right-aligned on the same line
  - Verify: The layout uses `HStack`; no `VStack` stacks label above value; label and value are on the same visual line
  - **Failure**: The `profileInfoRow` function uses `VStack` — label is rendered above the value, not beside it on the same horizontal line. Additionally, the value is enclosed in a `RoundedRectangle` background, violating the requirement that each line should not be enclosed by a rectangle.
  - **Root Cause**: `profileInfoRow` wraps both `Text` views in a `VStack(alignment: .leading, spacing: 10)`, stacking label on top and value below. The value `Text` also applies a `.background { RoundedRectangle(cornerRadius: 15).fill(.lightYellow).frame(height: 56) }`, creating a visible rectangle container around the value. Neither an `HStack` nor right-alignment of the value is present.
  - **Affected Files**: [Wishie/Screens/Profile/ProfileView.swift](../../../../../Wishie/Screens/Profile/ProfileView.swift) — `profileInfoRow` function (lines 74–92)
  - **Code Snippet**:
    ```swift
    private func profileInfoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {   // ❌ should be HStack
            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value.isEmpty ? "-" : value)
                .frame(maxWidth: .infinity, alignment: .leading)  // ❌ should be .trailing
                .padding(.horizontal, 15)
                .background {
                    RoundedRectangle(cornerRadius: 15)   // ❌ rectangle not allowed
                        .fill(.lightYellow)
                        .frame(height: 56)
                }
        }
    }
    ```
  - **Expected Behavior**: Each row should use an `HStack` placing the label `Text` left-aligned and the value `Text` right-aligned on the same visual line, with no enclosing rectangle around the value.
