# AC 1: WishlistDetail Real-Time Item Updates

- [x] **Scenario: Picked item status reflects automatically on WishlistDetailScreen**
  - Given: User `user-ac1-viewer` is viewing wishlist `wishlist-ac1-detail` on `WishlistDetailScreen`, which contains item `item-ac1-a` with `isPicked = false`
  - When: An external actor updates `item-ac1-a`'s `isPicked` field to `true` directly in Firestore
  - Then: `WishlistDetailScreen` automatically shows `item-ac1-a` as picked without any user-initiated navigation or refresh
  - Verify: `wishlistInfo` on `WishlistDetailViewController` is updated; the UI re-renders to reflect the picked state within the Firestore propagation window

- [x] **Scenario: Newly added wishlist item appears automatically on WishlistDetailScreen**
  - Given: User `user-ac1-viewer` is viewing wishlist `wishlist-ac1-detail` on `WishlistDetailScreen` with two existing items
  - When: An external actor adds a new item `item-ac1-new` to the `wishlist-ac1-detail` Firestore document
  - Then: `WishlistDetailScreen` automatically displays `item-ac1-new` in the list without user-initiated refresh
  - Verify: `wishlistInfo.wishlistItems` count increases by one and the new item is rendered in the list

- [x] **Scenario: Deleted wishlist item disappears automatically on WishlistDetailScreen**
  - Given: User `user-ac1-viewer` is viewing wishlist `wishlist-ac1-detail` on `WishlistDetailScreen` with item `item-ac1-del` present
  - When: An external actor removes `item-ac1-del` from the `wishlist-ac1-detail` Firestore document
  - Then: `WishlistDetailScreen` automatically removes `item-ac1-del` from the list without user-initiated refresh
  - Verify: `wishlistInfo.wishlistItems` no longer contains `item-ac1-del` and the UI re-renders accordingly
