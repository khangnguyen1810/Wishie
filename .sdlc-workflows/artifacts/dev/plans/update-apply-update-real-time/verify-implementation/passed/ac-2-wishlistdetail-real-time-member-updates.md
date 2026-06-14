# AC 2: WishlistDetail Real-Time Member Updates

- [x] **Scenario: New member joining wishlist is reflected automatically on WishlistDetailScreen**
  - Given: User `user-ac2-owner` is viewing wishlist `wishlist-ac2-detail` on `WishlistDetailScreen` with one member
  - When: User `user-ac2-friend` joins `wishlist-ac2-detail` (external membership change in Firestore)
  - Then: `WishlistDetailScreen` automatically updates `memberUsers` to include `user-ac2-friend` without user-initiated refresh
  - Verify: `memberUsers` array count increases by one and the new member avatar/info is rendered

