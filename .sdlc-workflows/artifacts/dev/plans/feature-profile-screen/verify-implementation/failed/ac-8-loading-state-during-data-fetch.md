# AC 8: Loading State During Data Fetch

- [x] **Scenario: A loading indicator is shown while user data is being fetched** ✅ RESOLVED
  - Given: `ProfileView` is presented for user `user-ac8-loading` and the `fetchUserInfo()` call is in progress
  - When: The `.task` modifier triggers `viewModel.fetchUserInfo()` on appearance
  - Then: A full-screen loading dialog (`showFullScreenDialog`) is displayed, blocking interaction until data is returned
  - Verify: `viewModel.isLoading` is `true` during the fetch; the loading overlay disappears once `fetchUserInfo()` completes (success or failure)
  - **Loading State Result**: ✅ PASS — `isLoading = true` is set at the start of `fetchUserInfo()` and correctly reset to `false` in all code paths (success, nil guard, catch). `.showFullScreenDialog($viewModel.isLoading)` is bound and `.task { await viewModel.fetchUserInfo() }` triggers on appearance.
  - **Root Cause 1 — Wrong layout direction**: ✅ RESOLVED — Replaced `VStack(alignment: .leading)` with `HStack(alignment: .center)` + `Spacer()` so the label is left-aligned and the value is right-aligned (trailing) in the same row.
    - **Affected File**: [Wishie/Screens/Profile/ProfileView.swift](Wishie/Screens/Profile/ProfileView.swift)
  - **Root Cause 2 — Value enclosed in a rectangle**: ✅ RESOLVED — Removed `.background { RoundedRectangle(cornerRadius: 15).fill(.lightYellow).frame(height: 56) }` from the value `Text`. Each row is now plain text with a `Divider()` separator and `.padding(.vertical, 14)` for clear spacing. No enclosing shape remains.
    - **Affected File**: [Wishie/Screens/Profile/ProfileView.swift](Wishie/Screens/Profile/ProfileView.swift)
