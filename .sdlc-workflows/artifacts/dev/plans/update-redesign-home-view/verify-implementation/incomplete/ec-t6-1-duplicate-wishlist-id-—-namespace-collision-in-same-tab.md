# EC-T6-1: Duplicate Wishlist ID — Namespace Collision in Same Tab

- [x] **Scenario: Two wishlists sharing the same ID in myList tab cause ambiguous zoom source geometry**
  - Given: `homeViewModel.myWishlists` contains two entries ('wishlist-t6ec1-dup-a', 'wishlist-t6ec1-dup-b') whose `WishlistModel.id` are both `"dup-id-001"`
  - When: The `myList` `ForEach` renders both cards and applies `.matchedTransitionSource(id: "dup-id-001", in: animation)` to each outer `ZStack`
  - Then: SwiftUI registers two sources with the same namespace key; tapping either card produces undefined zoom origin — the transition may animate from the wrong card bounds or produce a broken/snapping animation
  - Verify: Confirm data layer guarantees UUID uniqueness for `WishlistModel.id`; no two entries in the rendered list share the same `id` string; if this invariant is violated the transition degrades gracefully without a crash
