# AC 7: HomeView Task Uses Observation Instead of Conditional Fetch

- [x] **Scenario: HomeView .task registers snapshot listener rather than calling conditional getListWishlist**
  - Given: User `user-ac7-home` opens `HomeView` for the first time (empty wishlist state)
  - When: The `.task` modifier executes on screen appear
  - Then: `startObservingWishlists()` is called and a Firestore snapshot listener is registered on `users/{userId}/wishlists`; `getListWishlist()` is NOT invoked from `.task`
  - Verify: Membership changes in Firestore are automatically propagated to `HomeView`; the conditional `getListWishlist()` call is absent from the `.task` code path

