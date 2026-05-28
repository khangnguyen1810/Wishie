# EC 6: Delete the Only Remaining Item

- [x] **Scenario: Deleting the sole item in the list leaves an empty list without crashing**
  - Given: Wishlist 'wishlist-ec6-single' contains exactly one WishlistItemCard 'item-ec6-last' with a partially filled name
  - When: The user swipes left and taps "Delete" on 'item-ec6-last' via `.onDelete`
  - Then: The item is removed from `CreateWishlistViewModel`'s items array, the list renders with no cards (only the add-item row visible), and the app does not crash
  - Verify: Confirm the items array count drops to 0; confirm the add-item row remains interactive after deletion

