# EC 7: Save Button Bottom Padding on Devices with Home Indicator

- [ ] **Scenario: Save Button Has Visible Bottom Padding and Is Not Obscured by Home Indicator** ❌ FAILED
  - Given: User `"user-ec7-padding"` opens `InterestsSelectionView` on a device with a home indicator (e.g., iPhone 14 or later)
  - When: The screen fully renders with the "Save & Continue" button visible at the bottom
  - Then: The save button has a bottom padding that prevents it from being flush with or obscured by the home indicator safe area; the button is fully tappable
  - Verify: The button's bottom edge does not overlap the system home indicator region; a consistent bottom padding is visible between the button and the screen edge
  - **Failure**: No bottom padding is applied to the `WishieButton` in `InterestsSelectionView`. The button renders flush against the screen bottom edge, overlapping the home indicator safe area on devices with a home indicator.
  - **Root Cause**: `BaseWishieScreen` applies `.ignoresSafeArea()` to its `content` slot (`content.ignoresSafeArea()` in `BaseWishieScreen.swift`), which causes the content `VStack` (containing the `ScrollView` + `WishieButton`) to extend into the system safe area including the home indicator region. The `WishieButton` is called in `InterestsSelectionView` with no `.padding(.bottom, ...)` modifier, and its own default `verticalPadding` is `0`, so no vertical space is reserved between the button and the screen edge.
  - **Affected Files**:
    - `Wishie/Screens/Interests/InterestsSelectionView.swift` — `WishieButton` call has no bottom padding (the `VStack(spacing: 0)` containing the button has no bottom safe-area inset either)
    - `Wishie/CustomView/WishieButton.swift` — default `verticalPadding: CGFloat? = 0` means `.padding(.vertical, 0)` is applied, contributing zero bottom spacing
    - `Wishie/Screens/BaseWishieScreen.swift` — `content.ignoresSafeArea()` allows the content block to fill into the bottom safe area, so layout is not bounded by the home indicator inset
