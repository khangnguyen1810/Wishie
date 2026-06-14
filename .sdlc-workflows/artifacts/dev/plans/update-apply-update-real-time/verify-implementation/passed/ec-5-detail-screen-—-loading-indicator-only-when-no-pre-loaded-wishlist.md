# EC 5: Detail Screen — Loading Indicator Only When No Pre-loaded Wishlist

- [x] **Scenario: No loading indicator when `WishlistModel` is pre-loaded from HomeView**
  - Given: `WishlistDetailScreen 'detail-ec5-preloaded'` is opened with a pre-loaded `WishlistModel` (navigated from HomeView)
  - When: `startObservingWishlist(wishlistId:showInitialLoading: false)` is called in `.task`
  - Then: `isShowLoading` is NOT set to `true`; the wishlist data from the pre-loaded model is immediately visible; the listener still registers and receives subsequent real-time updates
  - Verify: Confirm `showInitialLoading` is `false` when a `WishlistModel` is passed; confirm the loading spinner never appears during this navigation path

- [x] **Scenario: Loading indicator shown when navigating via deep link with no pre-loaded wishlist**
  - Given: `WishlistDetailScreen 'detail-ec5-deeplink'` is opened via a route that only provides `wishlistId` (no `WishlistModel`)
  - When: `startObservingWishlist(wishlistId:showInitialLoading: true)` is called in `.task`
  - Then: `isShowLoading` is set to `true` immediately; a loading indicator is displayed; once the first Firestore snapshot arrives, `isShowLoading` is set to `false` and wishlist data is shown
  - Verify: Confirm `showInitialLoading` is `true` when no `WishlistModel` is pre-loaded; confirm the spinner appears and disappears at the correct lifecycle points

