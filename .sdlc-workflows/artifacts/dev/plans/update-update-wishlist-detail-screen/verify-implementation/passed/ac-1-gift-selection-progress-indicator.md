# AC 1: Gift Selection Progress Indicator

- [x] **Scenario: Progress bar displays correct fill and label when some items are picked**
  - Given: A wishlist `wishlist-ac1-progress` exists with 7 items total, 3 of which have `isPicked = true`
  - When: The owner or a member navigates to the WishlistDetail screen for `wishlist-ac1-progress`
  - Then: A horizontal progress bar appears in the header with fill ratio 3/7 and a text label reading "3 / 7 gifts selected"
  - Verify: The progress bar fill visually represents ~42.8% width; the label text matches the exact format "X / Y gifts selected"; the element is visible above the item list without being clipped

- [x] **Scenario: Progress bar updates after a member reserves an item**
  - Given: A wishlist `wishlist-ac1-reserve-update` exists with 5 items, 2 of which are already picked; a member is viewing the detail screen showing "2 / 5 gifts selected"
  - When: The member selects an unpicked item, confirms the reservation dialog with "OK", and the backend call succeeds
  - Then: The progress bar fill and label update to "3 / 5 gifts selected" without requiring a manual screen refresh
  - Verify: The progress bar re-renders automatically; the fill increases; the numeric label reflects the new count

- [x] **Scenario: Progress bar updates after the owner deletes an item**
  - Given: A wishlist `wishlist-ac1-delete-update` exists with 6 items, 2 picked; the owner is viewing the detail screen showing "2 / 6 gifts selected"
  - When: The owner deletes one unpicked item and confirms the deletion dialog
  - Then: The progress bar fill and label update to "2 / 5 gifts selected"
  - Verify: Total count decreases by 1; picked count remains unchanged; bar fill ratio recalculates correctly

---
