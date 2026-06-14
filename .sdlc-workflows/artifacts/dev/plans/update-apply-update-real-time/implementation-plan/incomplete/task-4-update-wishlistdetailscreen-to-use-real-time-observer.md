# Task 4: Update WishlistDetailScreen to Use Real-time Observer

- [ ] 4.1: In `Wishie/Screens/Detail/WishlistDetailScreen.swift` UPDATE:
  - Replace the existing `.task` modifier body:
    - Change `guard let wishlistId else { return }` to `let id = wishlistId ?? wishlist?.id` with `guard let id else { return }`
    - Replace `await viewModel.getWishlistInfo(wishListId: wishlistId)` with `viewModel.startObservingWishlist(wishlistId: id, showInitialLoading: wishlist == nil)`
    - This ensures that when navigating from `HomeView` (where `wishlist` is provided but `wishlistId` is nil), the wishlist ID is derived from `wishlist?.id` and no loading indicator is shown; when navigating via route (where `wishlistId` is provided but `wishlist` is nil), loading is shown until the first snapshot fires

