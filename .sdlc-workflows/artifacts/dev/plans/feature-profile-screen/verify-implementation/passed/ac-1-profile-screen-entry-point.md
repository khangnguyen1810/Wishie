# AC 1: Profile Screen Entry Point

- [x] **Scenario: Tapping the user avatar circle in HomeView presents ProfileView** ✅ RESOLVED
  - Given: A logged-in user named `user-ac1-entry` is on the Home screen with the top app bar visible
  - When: The user taps the circular user-avatar button (`Circle().fill(.lightYellow)`) in the top app bar
  - Then: `ProfileView` is presented as a sheet or modal on top of the Home screen
  - Verify: The screen title "Profile" is visible in the top app bar of the presented view; `BaseWishieScreen` is used as the root container
  - **Resolution**: Updated `profileInfoRow` in `ProfileView.swift`:
    1. Replaced `VStack(alignment: .leading, spacing: 10)` with `HStack(alignment: .center)` + `Spacer()` — label is now on the left, value on the right.
    2. Removed the `.background { RoundedRectangle(...) }` modifier — no rectangle enclosing each row.
    3. Added `Divider()` after each row's `HStack` for clear visual separation between items.
    4. Fixed double horizontal padding: removed inner `.padding(.horizontal, 16)` from the row; the outer `VStack.padding(.horizontal, 16)` provides the single 16pt margin.
    5. Wrapped the four `profileInfoRow` calls in a `VStack(spacing: 0)` so rows are grouped tightly with dividers, and the outer `VStack(spacing: 24)` provides spacing from the avatar above.

