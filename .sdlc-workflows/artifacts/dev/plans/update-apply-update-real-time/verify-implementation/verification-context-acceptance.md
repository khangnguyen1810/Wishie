# Verification Context — Acceptance Scenarios

## Purpose

Define testable acceptance scenarios in Given/When/Then format to verify the implementation meets functional requirements and success criteria.
This document serves as the single source of truth for acceptance verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "user-ac1-login", "product-ac2-checkout"). No two scenarios should share mutable state.

## Acceptance Scenarios:

### AC 1: WishlistDetail Real-Time Item Updates

- [ ] **Scenario: Picked item status reflects automatically on WishlistDetailScreen**
  - Given: User `user-ac1-viewer` is viewing wishlist `wishlist-ac1-detail` on `WishlistDetailScreen`, which contains item `item-ac1-a` with `isPicked = false`
  - When: An external actor updates `item-ac1-a`'s `isPicked` field to `true` directly in Firestore
  - Then: `WishlistDetailScreen` automatically shows `item-ac1-a` as picked without any user-initiated navigation or refresh
  - Verify: `wishlistInfo` on `WishlistDetailViewController` is updated; the UI re-renders to reflect the picked state within the Firestore propagation window

- [ ] **Scenario: Newly added wishlist item appears automatically on WishlistDetailScreen**
  - Given: User `user-ac1-viewer` is viewing wishlist `wishlist-ac1-detail` on `WishlistDetailScreen` with two existing items
  - When: An external actor adds a new item `item-ac1-new` to the `wishlist-ac1-detail` Firestore document
  - Then: `WishlistDetailScreen` automatically displays `item-ac1-new` in the list without user-initiated refresh
  - Verify: `wishlistInfo.wishlistItems` count increases by one and the new item is rendered in the list

- [ ] **Scenario: Deleted wishlist item disappears automatically on WishlistDetailScreen**
  - Given: User `user-ac1-viewer` is viewing wishlist `wishlist-ac1-detail` on `WishlistDetailScreen` with item `item-ac1-del` present
  - When: An external actor removes `item-ac1-del` from the `wishlist-ac1-detail` Firestore document
  - Then: `WishlistDetailScreen` automatically removes `item-ac1-del` from the list without user-initiated refresh
  - Verify: `wishlistInfo.wishlistItems` no longer contains `item-ac1-del` and the UI re-renders accordingly

### AC 2: WishlistDetail Real-Time Member Updates

- [ ] **Scenario: New member joining wishlist is reflected automatically on WishlistDetailScreen**
  - Given: User `user-ac2-owner` is viewing wishlist `wishlist-ac2-detail` on `WishlistDetailScreen` with one member
  - When: User `user-ac2-friend` joins `wishlist-ac2-detail` (external membership change in Firestore)
  - Then: `WishlistDetailScreen` automatically updates `memberUsers` to include `user-ac2-friend` without user-initiated refresh
  - Verify: `memberUsers` array count increases by one and the new member avatar/info is rendered

### AC 3: WishlistDetail Initial Loading State

- [ ] **Scenario: Loading indicator shown on initial load via deep link (no pre-loaded WishlistModel)**
  - Given: User `user-ac3-deeplink` launches the app via a deep link pointing to wishlist `wishlist-ac3-deep` with no prior `WishlistModel` in memory
  - When: `WishlistDetailScreen` appears and `startObservingWishlist(wishlistId: "wishlist-ac3-deep", showInitialLoading: true)` is called in `.task`
  - Then: `isShowLoading` is `true` until the first Firestore snapshot callback completes, after which `isShowLoading` becomes `false` and content is displayed
  - Verify: A loading indicator is visible on screen initially and disappears once wishlist data is populated

- [ ] **Scenario: No loading indicator when navigating from HomeView with pre-loaded WishlistModel**
  - Given: User `user-ac3-home` taps on wishlist `wishlist-ac3-home` from `HomeView`, passing a pre-loaded `WishlistModel` to `WishlistDetailScreen`
  - When: `WishlistDetailScreen` appears and `startObservingWishlist(wishlistId: "wishlist-ac3-home", showInitialLoading: false)` is called in `.task`
  - Then: `isShowLoading` remains `false` throughout the entire screen lifecycle; the pre-loaded data is displayed immediately
  - Verify: No loading indicator appears; wishlist content is visible from the first render frame

### AC 4: HomeView Real-Time Membership Updates

- [ ] **Scenario: Newly joined wishlist appears automatically on HomeView**
  - Given: User `user-ac4-home` has `HomeView` open showing their current wishlists; `myFriendWishlists` does not contain `wishlist-ac4-new`
  - When: User `user-ac4-home` is added as a member to wishlist `wishlist-ac4-new` in Firestore (e.g., via QR scan processed externally)
  - Then: `HomeView` automatically reflects `wishlist-ac4-new` in the appropriate wishlist section without user-initiated refresh
  - Verify: `myFriendWishlists` or `myWishlists` is updated to include `wishlist-ac4-new` and the UI re-renders

- [ ] **Scenario: Wishlist removed from membership disappears automatically from HomeView**
  - Given: User `user-ac5-home` has `HomeView` open with wishlist `wishlist-ac5-existing` visible in their list
  - When: `wishlist-ac5-existing` is deleted or user `user-ac5-home` is removed from its membership in Firestore
  - Then: `HomeView` automatically removes `wishlist-ac5-existing` from the displayed list without user-initiated refresh
  - Verify: Neither `myWishlists` nor `myFriendWishlists` contains `wishlist-ac5-existing` after the snapshot fires

### AC 5: HomeView Subsequent Updates Without Full-Screen Loading

- [ ] **Scenario: Subsequent real-time membership changes do not trigger full-screen loading dialog**
  - Given: User `user-ac5-reload` has `HomeView` fully loaded with `myWishlists` and `myFriendWishlists` both non-empty
  - When: A subsequent Firestore snapshot fires due to a membership change (e.g., a new wishlist is joined)
  - Then: `isGettingList` remains `false`; no full-screen loading dialog is shown; wishlists silently refresh in the background
  - Verify: The loading dialog is absent from the view hierarchy during the refresh; updated list data appears seamlessly

### AC 6: WishlistDetailScreen Task Uses Observation Instead of One-Time Fetch

- [ ] **Scenario: WishlistDetailScreen .task registers snapshot listener rather than calling getWishlistInfo**
  - Given: User `user-ac6-detail` navigates to `WishlistDetailScreen` for wishlist `wishlist-ac6`
  - When: The `.task` modifier executes on screen appear
  - Then: `startObservingWishlist` is called and a Firestore snapshot listener is registered; `getWishlistInfo` is NOT invoked
  - Verify: Subsequent Firestore changes to `wishlist-ac6` are automatically reflected; `getWishlistInfo` is not present in the `.task` call path

### AC 7: HomeView Task Uses Observation Instead of Conditional Fetch

- [ ] **Scenario: HomeView .task registers snapshot listener rather than calling conditional getListWishlist**
  - Given: User `user-ac7-home` opens `HomeView` for the first time (empty wishlist state)
  - When: The `.task` modifier executes on screen appear
  - Then: `startObservingWishlists()` is called and a Firestore snapshot listener is registered on `users/{userId}/wishlists`; `getListWishlist()` is NOT invoked from `.task`
  - Verify: Membership changes in Firestore are automatically propagated to `HomeView`; the conditional `getListWishlist()` call is absent from the `.task` code path

### AC 8: Firestore Listener Cleanup on Deallocation

- [ ] **Scenario: WishlistDetail Firestore listener is removed when WishlistDetailViewController is deallocated**
  - Given: User `user-ac8-detail` has `WishlistDetailScreen` open with the snapshot listener registered for wishlist `wishlist-ac8`
  - When: User navigates away from `WishlistDetailScreen`, causing `WishlistDetailViewController` to be deallocated
  - Then: `ListenerRegistration.remove()` is called in `deinit`; no further Firestore snapshot callbacks are delivered for `wishlist-ac8`
  - Verify: `deinit` on `WishlistDetailViewController` executes `remove()` on the stored `ListenerRegistration`; no callbacks fire after deallocation

- [ ] **Scenario: HomeView Firestore listener is removed when HomeViewModel is deallocated**
  - Given: User `user-ac8-home` has `HomeView` active with the wishlists snapshot listener registered
  - When: `HomeViewModel` is deallocated (e.g., user logs out or the view is torn down)
  - Then: `ListenerRegistration.remove()` is called in `HomeViewModel.deinit`; no further Firestore snapshot callbacks are delivered for the wishlists sub-collection
  - Verify: `deinit` on `HomeViewModel` executes `remove()` on the stored `ListenerRegistration`; no memory leak is present after deallocation
