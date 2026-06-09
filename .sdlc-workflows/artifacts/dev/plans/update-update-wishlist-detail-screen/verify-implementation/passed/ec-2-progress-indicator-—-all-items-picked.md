# EC 2: Progress Indicator — All Items Picked

- [x] **Scenario: Progress bar reaches 100% fill when every item is reserved**
  - Given: Wishlist `"wishlist-ec2-allpicked"` has `5` items and all `5` have `isPicked = true`
  - When: A member or owner views the `WishlistDetailScreen`
  - Then: The progress bar is completely filled and the label reads `"5 / 5 gifts selected"`
  - Verify: The bar fill value equals `1.0`; the label text is fully visible without truncation; no UI overflow or clipping occurs
