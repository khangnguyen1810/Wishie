# AC 4: Owner Delete Item via Bottom Sheet

- [x] **Scenario: Delete button is present for an unpicked item in the owner's bottom sheet**
  - Given: A wishlist `wishlist-ac4-delete` is owned by the logged-in user and contains an unpicked item `item-ac4-unpicked` (`isPicked = false`)
  - When: The owner taps `item-ac4-unpicked` to open the bottom sheet
  - Then: A "Delete" button is visible and enabled in the bottom sheet
  - Verify: The button is tappable; it is styled as a destructive action (e.g., red text or icon)

- [x] **Scenario: Delete button is hidden or disabled for an already-picked item**
  - Given: A wishlist `wishlist-ac4-picked-guard` is owned by the logged-in user and contains a picked item `item-ac4-picked` (`isPicked = true`)
  - When: The owner taps `item-ac4-picked` to open the bottom sheet
  - Then: The "Delete" button is hidden or disabled
  - Verify: The owner cannot initiate a delete action on the picked item; other bottom sheet content remains visible

- [x] **Scenario: Deletion confirmation dialog appears and item is removed on confirm**
  - Given: A wishlist `wishlist-ac4-confirm-delete` is owned by the logged-in user and contains unpicked item `item-ac4-to-delete`; the owner has opened the bottom sheet for that item
  - When: The owner taps "Delete" in the bottom sheet
  - Then: A confirmation dialog appears; upon tapping "OK", the item is removed from the list and deleted from Firestore; the progress bar updates accordingly
  - Verify: The dialog uses the existing `showDialogIfNeeded` pattern; the item row disappears from the list after confirmation; the backend `deleteWishlistItem` call is made exactly once

---

