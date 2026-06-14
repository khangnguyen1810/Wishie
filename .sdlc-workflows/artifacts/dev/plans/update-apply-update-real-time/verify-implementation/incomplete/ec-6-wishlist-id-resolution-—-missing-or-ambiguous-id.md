# EC 6: Wishlist ID Resolution — Missing or Ambiguous ID

- [x] **Scenario: Wishlist ID resolved from `wishlistId` route parameter when `wishlist` is nil**
  - Given: `WishlistDetailScreen 'detail-ec6-routeid'` is initialized with `wishlistId = "wl-ec6-route"` and `wishlist = nil`
  - When: `.task` fires and `startObservingWishlist` is called
  - Then: The Firestore listener is registered against document path `wishList/wl-ec6-route`; real-time updates are received correctly
  - Verify: Confirm the resolved ID equals `"wl-ec6-route"` and that no nil-dereference or crash occurs

- [x] **Scenario: Both `wishlistId` and `wishlist?.id` are nil — no listener registered**
  - Given: `WishlistDetailScreen 'detail-ec6-noid'` is initialized with both `wishlistId = nil` and `wishlist = nil`
  - When: `.task` fires and ID resolution is attempted
  - Then: `startObservingWishlist` is not called (or exits early); no Firestore listener is registered; the screen does not crash and may display an empty or error state
  - Verify: Confirm no unguarded force-unwrap or fatal error occurs; confirm no listener registration is attempted with an empty or invalid document path
