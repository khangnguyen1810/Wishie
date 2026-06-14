# AC 1: FAB Owner Visibility

- [x] **Scenario: Add item FAB renders only for wishlist owner**
  - Given: `WishlistDetailScreen` is loaded with wishlist data `'wishlist-ac1-owner'` where `wishlistInfo.isOwner()` returns `true`
  - When: The screen's view hierarchy is reviewed
  - Then: The "Add item" floating action button is conditionally present, gated by `viewModel.wishlistInfo.isOwner()`
  - Verify: Code review confirms the FAB is wrapped in an `if viewModel.wishlistInfo.isOwner()` guard; no FAB code path exists outside this guard

- [x] **Scenario: Add item FAB is absent for non-owner viewer**
  - Given: `WishlistDetailScreen` is loaded with wishlist data `'wishlist-ac1-viewer'` where `wishlistInfo.isOwner()` returns `false`
  - When: The screen's view hierarchy is reviewed
  - Then: No FAB or add-item entry point is rendered
  - Verify: Code review confirms there is no unconditional FAB render or alternative add-item trigger available to non-owners
