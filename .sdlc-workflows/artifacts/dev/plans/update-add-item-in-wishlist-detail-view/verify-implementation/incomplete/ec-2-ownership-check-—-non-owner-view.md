# EC 2: Ownership Check — Non-Owner View

- [x] **Scenario: Add item FAB is hidden for non-owner viewers**
  - Given: `WishlistDetailScreen` is displayed for wishlist `"wishlist-ec2-nonowner"` where `viewModel.wishlistInfo.isOwner()` returns `false`
  - When: The screen finishes loading and renders the item list
  - Then: The floating action button for adding items is not visible in the view hierarchy
  - Verify: Confirm the FAB rendering is gated on `viewModel.wishlistInfo.isOwner()` returning `true`

---
