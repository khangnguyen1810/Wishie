# Task 1: Extend WishlistService with addWishlistItem

- [ ] 1.1: In `Wishie/Services/WishlistService.swift` UPDATE:
  - Add `func addWishlistItem(wishlistId: String, item: WishlistItem) async throws -> Result<Bool, Error>` to `WishlistServiceProtocol`.
  - Implement `addWishlistItem` in `WishlistService`: fetch the Firestore document for `wishlistId` from the `"wishList"` collection, append a new item dictionary to `wishListItems` using `FieldValue.arrayUnion`, and call `updateData`. The item dictionary must include keys `id`, `name`, `description`, `imageUrl`, `isPicked`, `itemLink`, `price`, `isMostDesired` — matching the schema used in `createWishlist` and `updateWishlistItem`.

