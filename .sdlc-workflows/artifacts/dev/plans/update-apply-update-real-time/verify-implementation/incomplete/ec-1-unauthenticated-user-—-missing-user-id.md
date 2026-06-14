# EC 1: Unauthenticated User — Missing User ID

- [x] **Scenario: `observeUserWishlistIds` returns nil when userId is unavailable**
  - Given: `HomeViewModel 'home-ec1-noauth'` is initialized with no authenticated user (userId is nil or empty)
  - When: `startObservingWishlists()` is called
  - Then: `observeUserWishlistIds(onChange:)` returns `nil`, no Firestore snapshot listener is registered, and `myWishlists` / `myFriendWishlists` remain empty without crashing
  - Verify: Confirm the returned `ListenerRegistration?` is `nil`; confirm no Firestore network request is made; confirm the app does not crash or show an error dialog
