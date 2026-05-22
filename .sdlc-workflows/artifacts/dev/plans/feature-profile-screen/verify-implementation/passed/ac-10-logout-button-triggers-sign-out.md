# AC 10: Logout Button Triggers Sign-Out

- [x] **Scenario: Tapping the Logout button signs the user out** ✅ RESOLVED
  - Given: `ProfileView` is presented for authenticated user `user-ac10-logout`
  - When: The user taps the "Log out" `WishieButton` at the bottom of the screen
  - Then: `authViewModel.logOut()` is called, and the app navigates away from the authenticated flow (e.g., back to the Welcome or Sign-In screen)
  - Verify: The Logout button uses `wishiePink` fill and white title text; it is positioned at the bottom of the screen with at least 20 pt bottom padding; the button is always enabled regardless of loading state
  - **Resolution**: Refactored `profileInfoRow` in `ProfileView.swift` to use `HStack` with the label (`Text`) on the left and the value (`Text`) on the right separated by a `Spacer()`. Removed the `RoundedRectangle(cornerRadius: 15).fill(.lightYellow)` background from the value text. Added a `Divider()` at the bottom of each row inside a `VStack(spacing: 0)` for clear visual separation. Grouped all four info rows in a shared `VStack(spacing: 0)` so dividers stack seamlessly. The Logout button retains its `wishiePink` fill, white title, `enabled: true`, and `.padding(.bottom, 20)` positioning.
