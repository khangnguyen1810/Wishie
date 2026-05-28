# EC 9: Small Screen Layout (iPhone SE — 375pt width)

- [x] **Scenario: Image frame respects minHeight: 180 on smallest supported iPhone screen**
  - Given: The app runs on an iPhone SE (3rd gen, 375pt wide) and wishlist 'wishlist-ec9-smallscreen' contains 3 WishlistItemCards
  - When: The user scrolls through the item list
  - Then: Each card's image area renders with at least `minHeight: 180`, no content is clipped outside its card boundary, and no layout overflow or scrolling glitch occurs
  - Verify: Run on a 375pt simulator; measure each card's image frame height is ≥ 180pt; confirm no horizontal overflow
