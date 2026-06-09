# EC 6: Delete Protection — Picked Item via Swipe

- [x] **Scenario: Swipe-to-delete is suppressed on an already-reserved item row**
  - Given: Wishlist `"wishlist-ec6-swipe"` has item `"item-ec6-reserved"` with `isPicked = true`; the owner is viewing the native SwiftUI `List`
  - When: The owner performs a leading or trailing swipe gesture on `"item-ec6-reserved"`
  - Then: No delete swipe action appears; the swipe gesture is ignored or dismissed
  - Verify: The item row remains fully visible and correctly rendered after the swipe attempt; no accidental deletion occurs
