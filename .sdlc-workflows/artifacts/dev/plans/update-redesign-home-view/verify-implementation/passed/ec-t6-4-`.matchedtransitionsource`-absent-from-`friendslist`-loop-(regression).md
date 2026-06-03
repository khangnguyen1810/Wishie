# EC-T6-4: `.matchedTransitionSource` Absent from `friendsList` Loop (Regression)

- [x] **Scenario: Zoom transition is missing from the friendsList ForEach loop causing a plain push transition instead of zoom**
  - Given: Only the `myList` `ForEach` has `.matchedTransitionSource(id: wishlist.0.id, in: animation)` applied; the `friendsList` `ForEach` is missing the modifier
  - When: The user selects the `friendsList` tab and taps any entry ('wishlist-t6ec4-friends-no-zoom')
  - Then: `WishlistDetailScreen` opens with a standard slide push transition instead of the App Store zoom; no crash occurs but the visual spec is violated
  - Verify: Inspect `HomeView.swift` to confirm `.matchedTransitionSource(id: wishlist.0.id, in: animation)` is present on the outer `ZStack` in BOTH `myList` and `friendsList` `ForEach` closures; run the friends-list tap and confirm the zoom animation plays
