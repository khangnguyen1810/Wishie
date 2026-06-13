# EC 10: Member Cannot Reserve an Already-Picked Item

- [x] **Scenario: Reserve button is non-interactive for an item already picked by another member**
  - Given: Wishlist `"wishlist-ec10-alreadypicked"` has item `"item-ec10-taken"` with `isPicked = true` and `pickedUserId` set to a different user
  - When: A different member views the detail screen and taps on `"item-ec10-taken"`
  - Then: The "Reserve" button is disabled or not shown in the bottom sheet; no confirmation dialog is presented
  - Verify: No backend call is made; the bottom sheet displays the item's reserved state clearly without UI errors
