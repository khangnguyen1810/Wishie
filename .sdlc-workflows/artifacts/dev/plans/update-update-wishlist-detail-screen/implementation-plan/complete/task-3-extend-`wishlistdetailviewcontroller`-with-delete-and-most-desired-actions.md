# Task 3: Extend `WishlistDetailViewController` with delete and most-desired actions

- [ ] 3.1: In `Wishie/Screens/Detail/WishlistDetailViewController.swift` UPDATE:
  - Add `@Published var showDeleteConfirmation: Bool = false` after the existing `@Published var joinErrorMessage: String = ""`.
  - Add `@Published var showReserveConfirmation: Bool = false` directly after `showDeleteConfirmation`.
  - Implement `func deleteWishlistItem(wishlistId: String) async` following the pattern of `pickItem(wishlistId:)`:
    - Set `isShowLoading = true`.
    - Call `try await wishlistService.deleteWishlistItem(wishlistId: wishlistId, itemId: itemSelected.id)`.
    - On `.success`: set `isShowLoading = false` and call `await getWishlistInfo(wishListId: wishlistId)`.
    - On `.failure(let error)`: set `isShowLoading = false`, `errorMessage = error.localizedDescription`, `isShowError = true`.
    - In the `catch`: set `isShowLoading = false`, `errorMessage = error.localizedDescription`, `isShowError = true`.
  - Implement `func setMostDesired(wishlistId: String) async` following the same pattern:
    - Set `isShowLoading = true`.
    - Call `try await wishlistService.setMostDesired(wishlistId: wishlistId, itemId: itemSelected.id, isMostDesired: true)`.
    - On `.success`: set `isShowLoading = false` and call `await getWishlistInfo(wishListId: wishlistId)`.
    - On `.failure(let error)` and in `catch`: set `isShowLoading = false`, `errorMessage = error.localizedDescription`, `isShowError = true`.

---

