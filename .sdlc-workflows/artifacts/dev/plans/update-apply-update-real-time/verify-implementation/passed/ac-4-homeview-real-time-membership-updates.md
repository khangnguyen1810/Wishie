# AC 4: HomeView Real-Time Membership Updates

- [x] **Scenario: Newly joined wishlist appears automatically on HomeView**
  - Given: User `user-ac4-home` has `HomeView` open showing their current wishlists; `myFriendWishlists` does not contain `wishlist-ac4-new`
  - When: User `user-ac4-home` is added as a member to wishlist `wishlist-ac4-new` in Firestore (e.g., via QR scan processed externally)
  - Then: `HomeView` automatically reflects `wishlist-ac4-new` in the appropriate wishlist section without user-initiated refresh
  - Verify: `myFriendWishlists` or `myWishlists` is updated to include `wishlist-ac4-new` and the UI re-renders

- [x] **Scenario: Wishlist removed from membership disappears automatically from HomeView**
  - Given: User `user-ac5-home` has `HomeView` open with wishlist `wishlist-ac5-existing` visible in their list
  - When: `wishlist-ac5-existing` is deleted or user `user-ac5-home` is removed from its membership in Firestore
  - Then: `HomeView` automatically removes `wishlist-ac5-existing` from the displayed list without user-initiated refresh
  - Verify: Neither `myWishlists` nor `myFriendWishlists` contains `wishlist-ac5-existing` after the snapshot fires

