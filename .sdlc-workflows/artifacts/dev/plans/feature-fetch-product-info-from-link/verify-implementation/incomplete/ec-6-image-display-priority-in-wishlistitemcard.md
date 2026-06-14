# EC 6: Image Display Priority in WishlistItemCard

- [x] **Scenario: `localImage` is nil and `item.image` contains a remote URL**
  - Given: A `WishlistItem` 'item-ec6-remoteonly' where `localImage == nil` and `image == "https://cdn.example.com/product.jpg"`
  - When: `WishlistItemCard` renders this item
  - Then: `WishieWebImage` is displayed using `item.image`; no blank or placeholder image is shown where the remote image should appear
  - Verify: Confirm the card's image rendering logic checks `localImage` first and falls back to `WishieWebImage(url: item.image)` when `localImage` is `nil`

- [x] **Scenario: Both `localImage` and `item.image` are nil**
  - Given: A `WishlistItem` 'item-ec6-noimage' where both `localImage == nil` and `image == nil`
  - When: `WishlistItemCard` renders this item
  - Then: A placeholder or empty state is displayed; the app does not crash
  - Verify: Confirm the conditional rendering handles the double-nil case without force-unwrapping either value
