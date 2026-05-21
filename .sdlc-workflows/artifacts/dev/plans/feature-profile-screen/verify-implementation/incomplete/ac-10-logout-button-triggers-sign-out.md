# AC 10: Logout Button Triggers Sign-Out

- [ ] **Scenario: Tapping the Logout button signs the user out** ❌ FAILED
  - Given: `ProfileView` is presented for authenticated user `user-ac10-logout`
  - When: The user taps the "Log out" `WishieButton` at the bottom of the screen
  - Then: `authViewModel.logOut()` is called, and the app navigates away from the authenticated flow (e.g., back to the Welcome or Sign-In screen)
  - Verify: The Logout button uses `wishiePink` fill and white title text; it is positioned at the bottom of the screen with at least 20 pt bottom padding; the button is always enabled regardless of loading state
  - **Failure**: Profile information rows are not displayed with the required layout — label on the left and value on the right — and each row value is enclosed inside a rectangle, which is explicitly not allowed.
  - **Root Cause**:
    1. `profileInfoRow` uses a `VStack`, placing the label **above** the value instead of an `HStack` with the label on the **left** and value on the **right**.
    2. The value `Text` has a `RoundedRectangle(cornerRadius: 15).fill(.lightYellow)` background that encloses it in a visible box, violating the "no rectangle enclosure" requirement.
  - **Affected Files**:
    - `Wishie/Screens/Profile/ProfileView.swift` — `profileInfoRow` function (lines 79–96): uses `VStack` layout and applies a `RoundedRectangle` background to the value text.
  - **Code Snippet**:
    ```swift
    VStack(alignment: .leading, spacing: 10) {
        Text(label)
            .frame(maxWidth: .infinity, alignment: .leading)
        Text(value.isEmpty ? "-" : value)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 15)
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .fill(.lightYellow)
                    .frame(height: 56)
            }
    }
    ```
  - **Expected Behavior**: Each profile info row should use an `HStack` with the label aligned to the left and the value aligned to the right, with no background rectangle around any part of the row.
  - **Actual Behavior**: The label sits above the value in a `VStack`, and the value is wrapped in a `RoundedRectangle` filled with `.lightYellow`.
