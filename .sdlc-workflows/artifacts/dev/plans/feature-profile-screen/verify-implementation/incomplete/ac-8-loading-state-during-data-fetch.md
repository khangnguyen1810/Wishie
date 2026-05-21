# AC 8: Loading State During Data Fetch

- [ ] **Scenario: A loading indicator is shown while user data is being fetched** ❌ FAILED
  - Given: `ProfileView` is presented for user `user-ac8-loading` and the `fetchUserInfo()` call is in progress
  - When: The `.task` modifier triggers `viewModel.fetchUserInfo()` on appearance
  - Then: A full-screen loading dialog (`showFullScreenDialog`) is displayed, blocking interaction until data is returned
  - Verify: `viewModel.isLoading` is `true` during the fetch; the loading overlay disappears once `fetchUserInfo()` completes (success or failure)
  - **Loading State Result**: ✅ PASS — `isLoading = true` is set at the start of `fetchUserInfo()` and correctly reset to `false` in all code paths (success, nil guard, catch). `.showFullScreenDialog($viewModel.isLoading)` is bound and `.task { await viewModel.fetchUserInfo() }` triggers on appearance.
  - **Failure**: UI layout does not meet the stated requirements from USER_INPUT.
  - **Root Cause 1 — Wrong layout direction**: `profileInfoRow` uses a `VStack`, placing the label on top and value below. The requirement is a horizontal layout with the label on the left and the value on the right (`HStack`).
    - **Affected File**: [Wishie/Screens/Profile/ProfileView.swift](Wishie/Screens/Profile/ProfileView.swift)
    - **Code**:
      ```swift
      VStack(alignment: .leading, spacing: 10) {
          Text(label)    // label on top
          Text(value)    // value below
      }
      ```
    - **Expected**: `HStack` with `Text(label)` aligned leading and `Text(value)` aligned trailing.
  - **Root Cause 2 — Value enclosed in a rectangle**: The value `Text` has a `.background { RoundedRectangle(cornerRadius: 15).fill(.lightYellow).frame(height: 56) }`, which encloses each value in a rounded rectangle box. The requirement explicitly states each line must not be enclosed by a rectangle.
    - **Affected File**: [Wishie/Screens/Profile/ProfileView.swift](Wishie/Screens/Profile/ProfileView.swift)
    - **Code**:
      ```swift
      Text(value.isEmpty ? "-" : value)
          .padding(.horizontal, 15)
          .background {
              RoundedRectangle(cornerRadius: 15)
                  .fill(.lightYellow)
                  .frame(height: 56)
          }
      ```
    - **Expected**: Plain text value with no enclosing shape background.
