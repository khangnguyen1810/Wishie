# EC 4: Home Screen — No Loading Dialog on Subsequent Snapshots

- [x] **Scenario: `isGettingList` stays false when data is already loaded and a new snapshot arrives**
  - Given: `HomeViewModel 'home-ec4-noloadingflash'` already has non-empty `myWishlists` and `myFriendWishlists` loaded from the first snapshot
  - When: A second Firestore snapshot fires (e.g., a new wishlist is joined by the user)
  - Then: `isGettingList` is NOT set to `true`; the full-screen loading dialog is NOT shown; `myWishlists` and `myFriendWishlists` are updated silently via `refreshWishlists()`
  - Verify: Assert `isGettingList` remains `false` throughout the second snapshot processing; confirm UI does not flash the loading state

