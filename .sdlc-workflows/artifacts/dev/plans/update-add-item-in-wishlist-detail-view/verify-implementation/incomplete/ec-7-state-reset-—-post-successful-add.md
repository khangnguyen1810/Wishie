# EC 7: State Reset — Post-Successful Add

- [x] **Scenario: All new-item state fields are cleared after a successful item add**
  - Given: A successful add flow completes for item `"item-ec7-reset"` with name, description, image, and link all populated
  - When: `WishlistService.addWishlistItem` returns successfully
  - Then: `newItemName`, `newItemDescription`, `newItemImage`, `newItemLink`, and `metadataFetchError` are all reset to their initial/empty values
  - Verify: Confirm the post-success code path in the ViewController explicitly resets each of these five state properties
