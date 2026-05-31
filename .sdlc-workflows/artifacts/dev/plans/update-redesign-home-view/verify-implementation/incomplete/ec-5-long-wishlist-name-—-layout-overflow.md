# EC 5: Long Wishlist Name — Layout Overflow

- [ ] **Scenario: Wishlist card truncates an excessively long name without breaking the owner row**
  - Given: A `WishlistModel` ('wishlist-ec5-long-name') has `name` set to an 80-character string (e.g., `"Birthday Celebration For My Dearest Friend Who Loves Collecting Rare Vintage Items"`)
  - When: `HomeItemViewCell` renders the `HStack` containing the name `Text` and the owner row
  - Then: The name text truncates with `.tail` truncation; the owner name and avatar circle remain fully visible and do not get pushed off-screen; the card maintains its standard height
  - Verify: The name `Text` does not overlap the owner `HStack`; the card horizontal padding is preserved

