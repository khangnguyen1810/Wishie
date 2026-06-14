# AC 6: WishlistDetailScreen Task Uses Observation Instead of One-Time Fetch

- [x] **Scenario: WishlistDetailScreen .task registers snapshot listener rather than calling getWishlistInfo**
  - Given: User `user-ac6-detail` navigates to `WishlistDetailScreen` for wishlist `wishlist-ac6`
  - When: The `.task` modifier executes on screen appear
  - Then: `startObservingWishlist` is called and a Firestore snapshot listener is registered; `getWishlistInfo` is NOT invoked
  - Verify: Subsequent Firestore changes to `wishlist-ac6` are automatically reflected; `getWishlistInfo` is not present in the `.task` call path
