# EC 10: Empty State — Transition from Non-Empty to Empty

- [x] **Scenario: Empty state appears correctly after all wishlists are deleted from a previously populated tab**
  - Given: `HomeViewModel.myWishlists` starts with 2 wishlists ('wishlist-ec10-a', 'wishlist-ec10-b') displayed on "My list" tab
  - When: Both wishlists are deleted via swipe actions, leaving `myWishlists = []`
  - Then: The empty state view (with `gift_img` and themed copy) replaces the list without layout artifacts or stale card views remaining on screen
  - Verify: `contentUnavailable` overlay renders immediately after the last item is removed; no ghost card frames are visible

