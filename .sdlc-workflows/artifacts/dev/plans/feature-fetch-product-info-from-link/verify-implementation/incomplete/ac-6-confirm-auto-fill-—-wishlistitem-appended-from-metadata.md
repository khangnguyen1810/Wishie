# AC 6: Confirm Auto-Fill — WishlistItem Appended from Metadata

- [x] **Scenario: Confirming fetched metadata creates a new WishlistItem pre-filled from ProductMetadata**
  - Given: `PasteLinkSheet` has successfully fetched metadata with title `"ac6-product-title"`, description `"ac6-product-description"`, image URL `"https://img.example-ac6.com/thumb.jpg"`, price `"49.00"`, and source URL `"https://example-ac6.com/product"` (test data namespace: `ac6-confirm`)
  - When: The user taps the confirm/add button
  - Then: A new `WishlistItem` is appended to `CreateWishlistViewModel.items` with `name == "ac6-product-title"`, `description == "ac6-product-description"`, `image == "https://img.example-ac6.com/thumb.jpg"`, `price == "49.00"`, `itemLink == "https://example-ac6.com/product"`, and `localImage == nil`; `PasteLinkSheet` is dismissed
  - Verify:
    - The confirm action calls a method on `CreateWishlistViewModel` (e.g., `addItem(from:)`) that maps each `ProductMetadata` field to the corresponding `WishlistItem` property
    - `WishlistItem` has a `price: String?` field that is set from the metadata
    - The sheet's dismissal is triggered after the item is appended

---
