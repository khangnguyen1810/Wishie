# EC 8: Member Reservation Confirmation — Cancel Has No Side Effects

- [x] **Scenario: Tapping Cancel on the reservation confirmation dialog does not reserve the item**
  - Given: Wishlist `"wishlist-ec8-cancelreserve"` has item `"item-ec8-free"` with `isPicked = false`; a member is viewing the detail screen
  - When: The member taps "Reserve" on `"item-ec8-free"` and then taps "Cancel" on the confirmation dialog
  - Then: `isPicked` remains `false`; `pickItem` backend service is NOT called; the progress bar value does not change
  - Verify: The item row renders as unreserved; the dialog is dismissed without any state mutation; the member can re-tap "Reserve" without issues

