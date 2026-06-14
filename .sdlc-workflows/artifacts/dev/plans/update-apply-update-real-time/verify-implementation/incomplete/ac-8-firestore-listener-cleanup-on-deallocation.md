# AC 8: Firestore Listener Cleanup on Deallocation

- [x] **Scenario: WishlistDetail Firestore listener is removed when WishlistDetailViewController is deallocated**
  - Given: User `user-ac8-detail` has `WishlistDetailScreen` open with the snapshot listener registered for wishlist `wishlist-ac8`
  - When: User navigates away from `WishlistDetailScreen`, causing `WishlistDetailViewController` to be deallocated
  - Then: `ListenerRegistration.remove()` is called in `deinit`; no further Firestore snapshot callbacks are delivered for `wishlist-ac8`
  - Verify: `deinit` on `WishlistDetailViewController` executes `remove()` on the stored `ListenerRegistration`; no callbacks fire after deallocation

- [x] **Scenario: HomeView Firestore listener is removed when HomeViewModel is deallocated**
  - Given: User `user-ac8-home` has `HomeView` active with the wishlists snapshot listener registered
  - When: `HomeViewModel` is deallocated (e.g., user logs out or the view is torn down)
  - Then: `ListenerRegistration.remove()` is called in `HomeViewModel.deinit`; no further Firestore snapshot callbacks are delivered for the wishlists sub-collection
  - Verify: `deinit` on `HomeViewModel` executes `remove()` on the stored `ListenerRegistration`; no memory leak is present after deallocation
