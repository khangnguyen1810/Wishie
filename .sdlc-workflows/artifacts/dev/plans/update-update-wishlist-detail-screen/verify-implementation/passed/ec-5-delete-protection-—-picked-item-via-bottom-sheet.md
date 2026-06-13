# EC 5: Delete Protection — Picked Item via Bottom Sheet

- [x] **Scenario: Delete CTA is hidden when the selected item is already reserved**
  - Given: Wishlist `"wishlist-ec5-picked"` has item `"item-ec5-reserved"` with `isPicked = true`; the owner is viewing the detail screen
  - When: The owner taps on `"item-ec5-reserved"` to open the bottom sheet
  - Then: The "Delete" button is hidden or disabled in the bottom sheet
  - Verify: No delete action can be triggered; the bottom sheet still displays other available CTAs correctly without layout gaps
