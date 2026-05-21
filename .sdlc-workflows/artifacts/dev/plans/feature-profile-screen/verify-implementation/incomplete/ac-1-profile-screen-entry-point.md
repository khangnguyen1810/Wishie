# AC 1: Profile Screen Entry Point

- [ ] **Scenario: Tapping the user avatar circle in HomeView presents ProfileView** ❌ FAILED
  - Given: A logged-in user named `user-ac1-entry` is on the Home screen with the top app bar visible
  - When: The user taps the circular user-avatar button (`Circle().fill(.lightYellow)`) in the top app bar
  - Then: `ProfileView` is presented as a sheet or modal on top of the Home screen
  - Verify: The screen title "Profile" is visible in the top app bar of the presented view; `BaseWishieScreen` is used as the root container
  - **Failure**: UI layout of `profileInfoRow` does not match requirements — label and value are stacked vertically (`VStack`) instead of displayed horizontally (label on the left, value on the right), and each value is enclosed inside a `RoundedRectangle` background which must be removed.
  - **Root Cause**:
    1. `profileInfoRow` uses `VStack(alignment: .leading, spacing: 10)` placing the label above the value. The requirement specifies a single horizontal row with the label on the left and value on the right (e.g., `HStack`).
    2. The value `Text` has `.background { RoundedRectangle(cornerRadius: 15).fill(.lightYellow).frame(height: 56) }` wrapping each value in a visible rectangle, which violates the "Each line should not be enclosed by a rectangle" requirement.
  - **Affected Files**:
    - [`Wishie/Screens/Profile/ProfileView.swift`](../../../../../Wishie/Screens/Profile/ProfileView.swift) — `profileInfoRow` function (lines 77–96)

    ```swift
    // Current (incorrect):
    VStack(alignment: .leading, spacing: 10) {
        Text(label)
            .font(.wishies(.regular, 16))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, alignment: .leading)
        Text(value.isEmpty ? "-" : value)
            .font(.wishies(.bold, 17))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 15)
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .fill(.lightYellow)
                    .frame(height: 56)
            }
    }

    // Expected: HStack with label on left, value on right, no rectangle background
    HStack {
        Text(label)
        Spacer()
        Text(value.isEmpty ? "-" : value)
    }
    ```
