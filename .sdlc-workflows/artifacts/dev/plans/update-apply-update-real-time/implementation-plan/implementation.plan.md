Real-time wishlist detail and home updates

# Requirement Context

## Current State

`WishlistDetailScreen` loads wishlist data once via `getWishlistInfo()` which calls Firebase Firestore's one-time `getDocument()`. `HomeView` loads the user's wishlists once via `getListWishlist()` which calls `getDocuments()`. Neither screen subscribes to real-time Firestore updates; users must manually navigate away and return to see changes made by other users (e.g., a friend picking a gift item).

## Goals

1. `WishlistDetailScreen` reflects real-time changes to the active wishlist document (item picked/unpicked, item added/deleted, member joined) without user-initiated refresh.
2. `HomeView` reflects real-time membership changes to the user's wishlists sub-collection (new wishlist joined, wishlist deleted/left) without user-initiated refresh.
3. Firestore listeners are registered when screens appear and released when view models are deallocated to prevent memory leaks.

## Risk & Mitigation

- **Double-fetch on initial load (Detail)**: The listener fires immediately upon registration with cached/current Firestore data. If `setInitialWishlist` is also called (when navigating from HomeView), the data is set twice in rapid succession. Mitigation: `setInitialWishlist` runs synchronously on `onAppear` before the async `.task` registers the listener, so the user sees data immediately with no visible flash.
- **Loading state on subsequent refreshes (Home)**: Showing a full-screen loading dialog on every membership change would degrade UX. Mitigation: `isGettingList` is set to `true` only when both `myWishlists` and `myFriendWishlists` are empty (initial load); subsequent listener callbacks call `refreshWishlists()` which skips the loading dialog.
- **Listener leak**: If `deinit` is not called (e.g., retained by a strong reference cycle), the Firestore listener would remain active. Mitigation: use `[weak self]` in all listener callbacks.

# Technical Specification Context

## Functional Requirements

- System MUST add `observeWishlist(by:onChange:)` to `WishlistServiceProtocol` returning `ListenerRegistration`
- System MUST add `observeUserWishlistIds(onChange:)` to `WishlistServiceProtocol` returning `ListenerRegistration?` (nil when `userId` is unavailable)
- System MUST implement `observeWishlist(by:onChange:)` in `WishlistService` using `addSnapshotListener` on the `wishList/{id}` Firestore document
- System MUST implement `observeUserWishlistIds(onChange:)` in `WishlistService` using `addSnapshotListener` on `users/{userId}/wishlists` ordered by `joinedAt`
- System MUST add `startObservingWishlist(wishlistId:showInitialLoading:)` to `WishlistDetailViewController` that registers the Firestore listener and updates `wishlistInfo`, `isShowLoading`, and `memberUsers` on each snapshot
- System MUST add `startObservingWishlists()` to `HomeViewModel` that registers the Firestore listener and silently refreshes `myWishlists` and `myFriendWishlists` on each snapshot
- System MUST add `deinit` to `WishlistDetailViewController` and `HomeViewModel` to remove their respective Firestore listeners
- System MUST update `WishlistDetailScreen`'s `.task` modifier to call `startObservingWishlist` instead of `getWishlistInfo`, resolving the wishlist ID from either `wishlistId` or `wishlist?.id`
- System MUST update `HomeView`'s `.task` modifier to call `startObservingWishlists()` instead of the conditional `getListWishlist()`

## Non-Functional Requirements

- System MUST deliver real-time updates using Firestore SDK's built-in snapshot listener mechanism (no polling)
- System MUST avoid memory leaks by using `[weak self]` in all listener callbacks and calling `ListenerRegistration.remove()` in `deinit`
- System MUST NOT show the full-screen loading dialog on home screen for subsequent background refreshes when data is already loaded
- System MUST show loading indicator on initial load of `WishlistDetailScreen` only when no pre-loaded `WishlistModel` is passed (i.e., navigating via deep link / route)
