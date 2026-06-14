# EC 2: Memory Leak Prevention — Listener Removed on Deinit

- [x] **Scenario: `WishlistDetailViewController` removes Firestore listener on deallocation**
  - Given: `WishlistDetailViewController 'detail-ec2-deinit'` has an active Firestore listener registered via `startObservingWishlist(wishlistId:showInitialLoading:)`
  - When: The view model is deallocated (navigated away, strong reference released)
  - Then: `deinit` is called, `ListenerRegistration.remove()` is invoked exactly once, and no further snapshot callbacks are received after deallocation
  - Verify: Confirm `deinit` calls `.remove()` on the listener; confirm no crash or memory leak is reported by instruments after deallocation

- [x] **Scenario: `HomeViewModel` removes Firestore listener on deallocation**
  - Given: `HomeViewModel 'home-ec2-deinit'` has an active Firestore listener registered via `startObservingWishlists()`
  - When: The view model is deallocated (user logs out or root is replaced)
  - Then: `deinit` is called, `ListenerRegistration.remove()` is invoked exactly once, and no further snapshot callbacks are received
  - Verify: Confirm `deinit` calls `.remove()` on the stored listener registration; confirm no retain cycle keeps the view model alive after navigation

