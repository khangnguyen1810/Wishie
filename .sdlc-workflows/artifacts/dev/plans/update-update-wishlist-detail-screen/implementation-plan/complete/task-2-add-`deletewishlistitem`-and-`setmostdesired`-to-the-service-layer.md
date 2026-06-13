# Task 2: Add `deleteWishlistItem` and `setMostDesired` to the service layer

- [ ] 2.1: In `Wishie/Services/WishlistService.swift` UPDATE — `WishlistServiceProtocol`:
  - Append `func deleteWishlistItem(wishlistId: String, itemId: String) async throws -> Result<Bool, Error>` to the protocol body.
  - Append `func setMostDesired(wishlistId: String, itemId: String, isMostDesired: Bool) async throws -> Result<Bool, Error>` to the protocol body.

- [ ] 2.2: In `Wishie/Services/WishlistService.swift` UPDATE — `WishlistService` implementation:
  - Implement `deleteWishlistItem(wishlistId:itemId:)` following the same `do/catch → Result` pattern used by `pickItem(wishlistId:itemId:)`:
    - Obtain `docRef` for `db.collection("wishList").document(wishlistId)`.
    - Fetch the document snapshot and guard-unwrap `data["wishListItems"] as? [[String: Any]]`.
    - Filter out the element whose `"id"` key equals `itemId`.
    - Call `docRef.updateData(["wishListItems": filteredItems])`.
    - Return `.success(true)` on success and `.failure(error)` in the `catch`.
  - Implement `setMostDesired(wishlistId:itemId:isMostDesired:)` following the same pattern used by `updateWishlistItem(wishlistId:itemId:newName:newDescription:newImage:)`:
    - Fetch and guard-unwrap `wishListItems` from the document.
    - Iterate over item indices; when `items[index]["id"] == itemId`, set `items[index]["isMostDesired"] = isMostDesired` and break.
    - Call `docRef.updateData(["wishListItems": items])`.
    - Return `.success(true)` on success and `.failure(error)` in the `catch`.

---

