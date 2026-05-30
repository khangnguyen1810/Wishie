# EC 2: Gradient Theme Fallback — nil themeColor

- [x] **Scenario: Wishlist with nil themeColor renders sunset fallback gradient**
  - Given: A `WishlistModel` ('wishlist-ec2-nil-theme') has `themeColor = nil`
  - When: `HomeItemViewCell` renders the card background
  - Then: `item.0.theme` resolves to `.sunset` via the `?? "sunset"` fallback in `WishlistModel.theme`; the card renders the sunset gradient without any transparent or missing fill
  - Verify: Card background shows a non-empty gradient; no blank/white card appears in the list
