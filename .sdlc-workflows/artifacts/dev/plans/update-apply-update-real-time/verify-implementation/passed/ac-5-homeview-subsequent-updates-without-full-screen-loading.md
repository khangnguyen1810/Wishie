# AC 5: HomeView Subsequent Updates Without Full-Screen Loading

- [x] **Scenario: Subsequent real-time membership changes do not trigger full-screen loading dialog**
  - Given: User `user-ac5-reload` has `HomeView` fully loaded with `myWishlists` and `myFriendWishlists` both non-empty
  - When: A subsequent Firestore snapshot fires due to a membership change (e.g., a new wishlist is joined)
  - Then: `isGettingList` remains `false`; no full-screen loading dialog is shown; wishlists silently refresh in the background
  - Verify: The loading dialog is absent from the view hierarchy during the refresh; updated list data appears seamlessly

