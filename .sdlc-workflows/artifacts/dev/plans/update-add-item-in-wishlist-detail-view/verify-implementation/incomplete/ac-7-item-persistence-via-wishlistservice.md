# AC 7: Item Persistence via WishlistService

- [x] **Scenario: addWishlistItem is called with correct wishlistId and constructed item**
  - Given: All required fields are filled for item `'item-ac7-persist'` in `WishlistDetailViewController`
  - When: The add action method is reviewed
  - Then: `WishlistService.addWishlistItem(wishlistId:item:)` is called with the current wishlist's ID and a `WishlistItem` constructed from `newItemName`, `newItemDescription`, the uploaded image URL, and `newItemLink`
  - Verify: Code review confirms the `WishlistItem` model is populated from `viewModel` state properties before being passed to the service, with no hard-coded or placeholder values
