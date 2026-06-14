# Task 2: Add Real-time Listener Management to WishlistDetailViewController

- [ ] 2.1: In `Wishie/Screens/Detail/WishlistDetailViewController.swift` UPDATE:
  - Add `import FirebaseFirestore` at the top of the file (after existing imports)
  - Add private stored property `private var wishlistListener: ListenerRegistration?`
  - Add `func startObservingWishlist(wishlistId: String, showInitialLoading: Bool = false)`:
    - Set `isShowLoading = showInitialLoading`
    - Call `wishlistListener?.remove()` to clean up any previous listener
    - Call `wishlistService.observeWishlist(by: wishlistId)` and store the result in `wishlistListener`
    - In the `onChange` closure, wrap updates in `Task { @MainActor [weak self] in }`: set `self.wishlistInfo = updatedWishlist`, set `self.isShowLoading = false`, `await self.fetchMemberUsers()`
  - Add `deinit { wishlistListener?.remove() }`

