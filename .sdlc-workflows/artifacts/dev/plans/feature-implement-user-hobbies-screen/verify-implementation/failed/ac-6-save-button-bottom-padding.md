# AC 6: Save Button Bottom Padding

- [x] **Scenario: Save button has bottom padding and does not stick to the screen edge** ✅ RESOLVED
  - Given: `InterestsSelectionView` is displayed on a device with a home indicator or any screen size
  - When: the user scrolls to the bottom of the interests list
  - Then: the "Save & Continue" button has visible bottom padding that separates it from the screen's bottom edge
  - Verify: the button is not obscured by the home indicator or device safe area; there is a consistent spacing between the button's bottom edge and the screen boundary
  - **Failure**: The button has no bottom padding — it sits flush against the bottom screen edge with no visible separation from the home indicator or safe area boundary.
  - **Root Cause**: In `InterestsSelectionView`, `WishieButton` is placed inside a `VStack(spacing: 0)` with no `.padding(.bottom, ...)` applied. `WishieButton`'s `verticalPadding` parameter defaults to `0`, so `.padding(.vertical, 0)` is applied by the button itself. Additionally, `BaseWishieScreen` applies `.ignoresSafeArea()` to the entire `content` block, allowing the button to extend below the device's safe area boundary (home indicator region).
  - **Affected Files**:
    - `Wishie/Screens/Interests/InterestsSelectionView.swift` — `WishieButton` call with no bottom padding modifier and outer `VStack(spacing: 0)`
    - `Wishie/Screens/BaseWishieScreen.swift` — `content.ignoresSafeArea()` allows button to render below the home indicator safe area
  - **Resolution**: Added `.padding(.bottom, 20)` to `WishieButton` in `InterestsSelectionView.swift`, creating 20pt of visible separation between the button's bottom edge and the physical screen boundary, preventing it from sitting flush against the home indicator region.
