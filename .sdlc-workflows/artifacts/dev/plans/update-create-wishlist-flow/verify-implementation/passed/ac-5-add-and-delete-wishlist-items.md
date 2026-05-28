# AC 5: Add and Delete Wishlist Items

- [x] **Scenario: User can append a new empty item via the styled add-item row**
  - Given: `CreateWishlistPage2` is shown with one existing `WishlistItem` "item-ac5-existing" in the list
  - When: The user taps the styled add-item row at the bottom of the list
  - Then: A new `WishlistItem()` is appended to the list and a new `WishlistItemCard` becomes visible
  - Verify: The list count increases by one; the newly appended card has empty name, description, and itemLink fields and shows the upload placeholder

- [x] **Scenario: User can delete an existing item via swipe-to-delete**
  - Given: `CreateWishlistPage2` is shown with two `WishlistItem` entries "item-ac5-delete-a" and "item-ac5-delete-b"
  - When: The user swipe-deletes "item-ac5-delete-a"
  - Then: The item is removed from the list and only "item-ac5-delete-b" remains
  - Verify: The list count decreases by one; the deleted card is no longer visible; the remaining card retains its data unchanged

