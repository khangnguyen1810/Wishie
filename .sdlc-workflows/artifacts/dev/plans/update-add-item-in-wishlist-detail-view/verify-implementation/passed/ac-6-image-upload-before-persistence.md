# AC 6: Image Upload Before Persistence

- [x] **Scenario: Image upload precedes Firestore item creation when an image is selected**
  - Given: A user has selected an image in `AddItemManualDetailSheet` for item `'item-ac6-image'` and entered a valid name
  - When: The add action method in `WishlistDetailViewController` is reviewed
  - Then: `WishlistService.upload(image:fileName:)` is called first, and `WishlistService.addWishlistItem(wishlistId:item:)` is only called upon a successful upload result; an upload failure stops execution and surfaces an error
  - Verify: Code review confirms the sequential `async/await` or callback chain with upload as a prerequisite; no path exists where `addWishlistItem` is called when upload has failed
