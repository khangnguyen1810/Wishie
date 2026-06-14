# EC 4: Image Upload Failure

- [x] **Scenario: Wishlist item is not persisted when image upload fails**
  - Given: `AddItemManualDetailSheet` has `newItemName` set to `"item-ec4-uploadfail"` and a selected image in `newItemImage`
  - When: `WishlistService.upload(image:fileName:)` throws or returns an error during the add flow
  - Then: `WishlistService.addWishlistItem(wishlistId:item:)` is never called, and `isShowError` is set to `true` with a relevant `errorMessage`
  - Verify: Confirm the ViewController's add logic awaits the upload result and only proceeds to `addWishlistItem` on success; an error short-circuits to the error state

---
