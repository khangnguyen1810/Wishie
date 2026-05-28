# EC 8: Very Long itemLink URL

- [x] **Scenario: An extremely long URL in itemLink does not break layout or crash**
  - Given: WishlistItemCard 'item-ec8-longurl' has a 2000-character URL string bound to `WishlistItem.itemLink`
  - When: The card renders in the list
  - Then: The `itemLink` text field displays without horizontal overflow, does not push sibling views out of bounds, and the card layout remains stable
  - Verify: Scroll through the list while 'item-ec8-longurl' is visible; confirm no layout constraints are broken and no crash occurs

