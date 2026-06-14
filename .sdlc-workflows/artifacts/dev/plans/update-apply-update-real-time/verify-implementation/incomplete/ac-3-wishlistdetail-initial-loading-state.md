# AC 3: WishlistDetail Initial Loading State

- [x] **Scenario: Loading indicator shown on initial load via deep link (no pre-loaded WishlistModel)**
  - Given: User `user-ac3-deeplink` launches the app via a deep link pointing to wishlist `wishlist-ac3-deep` with no prior `WishlistModel` in memory
  - When: `WishlistDetailScreen` appears and `startObservingWishlist(wishlistId: "wishlist-ac3-deep", showInitialLoading: true)` is called in `.task`
  - Then: `isShowLoading` is `true` until the first Firestore snapshot callback completes, after which `isShowLoading` becomes `false` and content is displayed
  - Verify: A loading indicator is visible on screen initially and disappears once wishlist data is populated

- [x] **Scenario: No loading indicator when navigating from HomeView with pre-loaded WishlistModel**
  - Given: User `user-ac3-home` taps on wishlist `wishlist-ac3-home` from `HomeView`, passing a pre-loaded `WishlistModel` to `WishlistDetailScreen`
  - When: `WishlistDetailScreen` appears and `startObservingWishlist(wishlistId: "wishlist-ac3-home", showInitialLoading: false)` is called in `.task`
  - Then: `isShowLoading` remains `false` throughout the entire screen lifecycle; the pre-loaded data is displayed immediately
  - Verify: No loading indicator appears; wishlist content is visible from the first render frame
