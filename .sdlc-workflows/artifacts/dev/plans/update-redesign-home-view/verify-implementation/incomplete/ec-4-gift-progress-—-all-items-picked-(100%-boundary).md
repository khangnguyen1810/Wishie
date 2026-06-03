# EC 4: Gift Progress — All Items Picked (100% Boundary)

- [ ] **Scenario: Wishlist card renders full progress when all items are picked**
  - Given: A `WishlistModel` ('wishlist-ec4-all-picked') has 5 `WishlistItem` entries, each with `isPicked = true`
  - When: `HomeItemViewCell` renders the card
  - Then: Progress evaluates to `5/5 = 1.0`; `GiftProgressView` renders at 100% fill; the gift count label displays "5/5 gifts"
  - Verify: `GiftProgressView` visually completes its ring/arc; no overflow or label truncation occurs at the boundary value

