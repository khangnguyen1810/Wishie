# Share Context

## Important Instructions for Implementation

- All Firestore listener closures MUST use `[weak self]` to prevent retain cycles
- All `@MainActor`-isolated property updates from listener callbacks MUST be wrapped in `Task { @MainActor [weak self] in }`
- `ListenerRegistration` (from `FirebaseFirestore`) MUST be stored as a private property and removed in `deinit`
- Do NOT add loading state (`isGettingList`, `isShowLoading`) for subsequent real-time listener callbacks in `HomeViewModel` — only on initial load
- Do NOT remove the `.refreshable` pull-to-refresh block in `HomeView`; it remains as an explicit user-initiated refresh path
- Do NOT remove `setInitialWishlist` from `WishlistDetailViewController`; it is still used by `WishlistDetailScreen.onAppear` for immediate content display when navigating from `HomeView`
- `WishlistDetailViewController` and `HomeViewModel` must add `import FirebaseFirestore` since `ListenerRegistration` is a FirebaseFirestore type

## Reused Existing Functions/Utilities

- `WishlistModel(dictionary:)`: Failable initializer for parsing Firestore document data into `WishlistModel`; located in `Wishie/Models/WishlistModel.swift`
- `getWishlist(by:)`: Fetches a `WishlistModel` and its owner `UserModel` from Firestore; located in `Wishie/Services/WishlistService.swift` — reused by `getUserWishlists()` which is reused by `refreshWishlists()`
- `getUserWishlists()`: Fetches all user wishlist tuples `[(WishlistModel, UserModel)]`; located in `Wishie/Services/WishlistService.swift` — reused inside `refreshWishlists()`
- `fetchMemberUsers()`: Fetches `UserModel` for each member ID from `wishlistInfo.members`; located in `Wishie/Screens/Detail/WishlistDetailViewController.swift` — called inside listener callback
- `setInitialWishlist(_:)`: Sets `wishlistInfo` from a pre-loaded `WishlistModel` and triggers `fetchMemberUsers()`; located in `Wishie/Screens/Detail/WishlistDetailViewController.swift` — still invoked by `WishlistDetailScreen.onAppear`
- `WishieConstants.userIdKey`: Key for retrieving userId from `UserDefaults`; `"userid"`; located in `Wishie/Constants/WishieConstants.swift`
- `WishieConstants.firebaseUserPath`: Firestore collection path `"users"`; located in `Wishie/Constants/WishieConstants.swift`
- `WishieConstants.firebaseWishlistPath`: Firestore sub-collection path `"wishlists"`; located in `Wishie/Constants/WishieConstants.swift`

## Shared Contracts

### Interfaces

- `WishlistServiceProtocol`: Extended with two new methods — `observeWishlist(by:onChange:) -> ListenerRegistration` and `observeUserWishlistIds(onChange:) -> ListenerRegistration?`; defined in `Wishie/Services/WishlistService.swift`

---

