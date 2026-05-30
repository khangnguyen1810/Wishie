# EC 6: Long Description Text — Line Clamping

- [x] **Scenario: Wishlist card clamps a description exceeding 2 lines without breaking card height**
  - Given: A `WishlistModel` ('wishlist-ec6-long-desc') has `description` set to a 5-line paragraph (~200 characters)
  - When: `HomeItemViewCell` renders the description `Text` with `lineLimit(2)`
  - Then: The description is clamped to exactly 2 lines with trailing truncation; the `GiftProgressView` circular element alongside it remains vertically aligned to `.top`; the overall card height is consistent with other cards
  - Verify: No text overflow beyond the 2-line boundary; the `HStack(alignment: .top)` keeps the progress ring anchored to the top of the description area
