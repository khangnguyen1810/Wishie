# EC-T6-6: `.matchedTransitionSource` Applied to Wrong View (HomeItemViewCell Instead of Outer ZStack)

- [x] **Scenario: Applying matchedTransitionSource to HomeItemViewCell directly produces incorrect zoom bounds**
  - Given: A hypothetical misconfiguration where `.matchedTransitionSource(id: wishlist.0.id, in: animation)` is placed on `HomeItemViewCell` instead of the enclosing outer `ZStack`
  - When: The user taps 'wishlist-t6ec6-wrong-placement' and the zoom transition fires
  - Then: The zoom origin bounds correspond to the cell's inner content area rather than the full card `ZStack` bounds, causing a visual mismatch where the zoom appears to originate from an inner rect; the hidden `NavigationLink` layer is excluded from the geometry capture
  - Verify: Confirm in `HomeView.swift` that `.matchedTransitionSource` is chained on the outer `ZStack` (after `.contentShape(Rectangle())`), NOT on `HomeItemViewCell(_:)`; the transition visually covers the entire card including padding areas
