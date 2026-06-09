# EC 4: isMostDesired Toggle — All Items Marked

- [x] **Scenario: Every item in a wishlist can be independently marked as most desired simultaneously**
  - Given: Wishlist `"wishlist-ec4-allstar"` has `3` items `"item-ec4-a"`, `"item-ec4-b"`, `"item-ec4-c"`, all with `isMostDesired = false`
  - When: The owner marks each item as most desired one by one via the bottom sheet
  - Then: All three items display a star badge; marking one item does not remove the badge from previously marked items
  - Verify: Each item row renders its star badge without layout overlap, truncation, or misalignment; the list scrolls smoothly
