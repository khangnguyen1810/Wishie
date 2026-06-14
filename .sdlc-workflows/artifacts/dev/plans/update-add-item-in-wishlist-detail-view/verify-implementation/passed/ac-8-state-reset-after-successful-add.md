# AC 8: State Reset After Successful Add

- [x] **Scenario: All new-item state properties are reset after a successful add**
  - Given: An item `'item-ac8-reset'` has been successfully added (both upload and `addWishlistItem` completed without error)
  - When: The success path of the add action in `WishlistDetailViewController` is reviewed
  - Then: `newItemName`, `newItemDescription`, `newItemImage`, `newItemLink`, and `metadataFetchError` are all reset to their default empty/nil values in the same success branch
  - Verify: Code review confirms all five state properties are explicitly reset; no property is left stale after a successful operation

