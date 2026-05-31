# EC 3: Gift Progress — Zero Items (Empty Wishlist)

- [ ] **Scenario: Wishlist card renders zero progress without division-by-zero when items array is empty**
  - Given: A `WishlistModel` ('wishlist-ec3-no-items') has `items = []` (count = 0)
  - When: `HomeItemViewCell` calculates progress as `items.count > 0 ? Double(itemPicked.count) / Double(items.count) : 0.0`
  - Then: `GiftProgressView` renders at 0% progress; the gift count label displays "0 gifts" with no crash or NaN/infinity value
  - Verify: No division-by-zero runtime error occurs; `GiftProgressView(progress: 0.0)` renders an empty ring; the label uses the `else` branch showing "0 gifts"

