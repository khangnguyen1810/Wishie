# AC 1: Fixed Image Frame Rendering

- [x] **Scenario: WishlistItemCard renders selected image at fixed frame with consistent cropping** ✅ RESOLVED
  - Given: A `WishlistItem` named "item-ac1-image" has an image selected and is rendered inside `WishlistItemCard`
  - When: The card appears on screen
  - Then: The image container fills the full available width (`maxWidth: .infinity`) with a minimum height of 180 pt, the image content scales to fill using `.scaledToFill()`, and is clipped to a continuous `RoundedRectangle(cornerRadius: 12)` with no overflow outside the frame
  - Verify: Inspect the view hierarchy to confirm `frame(maxWidth: .infinity, minHeight: 180)`, `.scaledToFill()`, and `clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))` are applied to the image; confirm that images of different aspect ratios (portrait, landscape, square) all crop uniformly within the same visible area
  - **Failure**: `frame(maxWidth: .infinity, minHeight: 180)` is not present. The verify criterion explicitly requires a single combined frame modifier with a flexible minimum height of 180 pt. The implementation uses two separate frame modifiers that fix the height at exactly 196 pt.
  - **Root Cause**: `WishlistItemCard` declares `private let imageHeight: CGFloat = 196` and applies `.frame(maxWidth: .infinity)` followed by `.frame(height: imageHeight)` on both the `ZStack` container and the inner `Image`. Using `height:` (fixed sizing) instead of `minHeight:` (flexible minimum) means the container cannot grow beyond 196 pt and the AC-specified `minHeight: 180` contract is never expressed in the view hierarchy.
  - **Affected Files**: `Wishie/Screens/CreateList/CreateWishlistPage2.swift`
    - Line 64: `private let imageHeight: CGFloat = 196` — introduces fixed height constant instead of the specified 180 pt minimum
    - Lines 90–91: `.frame(maxWidth: .infinity).frame(height: imageHeight)` on the selected `Image` — uses fixed height, not `minHeight: 180`
    - Lines 100–101: `.frame(maxWidth: .infinity).frame(height: imageHeight)` on the `ZStack` container — same issue; expected `.frame(maxWidth: .infinity, minHeight: 180)`
  - **Resolution**: Removed `private let imageHeight: CGFloat = 196` constant. Replaced `.frame(maxWidth: .infinity).frame(height: imageHeight)` on the selected `Image` with `.frame(maxWidth: .infinity, minHeight: 180)`. Replaced `.frame(maxWidth: .infinity).frame(height: imageHeight)` on the `ZStack` container with `.frame(maxWidth: .infinity, minHeight: 180)`. Updated `ImagePickerBox` height argument from the removed constant to `180`.

