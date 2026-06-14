# EC 5: Firestore Persistence Failure After Successful Image Upload

- [x] **Scenario: Error is surfaced when Firestore add fails after image is already uploaded**
  - Given: `WishlistService.upload(image:fileName:)` succeeds for wishlist item `"item-ec5-fsfail"` and returns a valid image URL
  - When: `WishlistService.addWishlistItem(wishlistId:item:)` throws or returns an error
  - Then: `isShowError` is set to `true` with a relevant `errorMessage`; new-item state is NOT reset (preserving user input for retry)
  - Verify: Confirm the error branch in the ViewController sets the error state and does not invoke the state-reset logic

---

