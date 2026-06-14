# Verification Context — Edge Case Scenarios

## Purpose

Define testable edge case scenarios in Given/When/Then format to verify the implementation handles boundary conditions, error states, and non-functional requirements.
This document serves as the single source of truth for edge case verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "cart-ec1-empty", "user-ec2-locked"). No two scenarios should share mutable state.

## Edge Case Scenarios:

### EC 1: Unauthenticated User — Missing User ID

- [ ] **Scenario: `observeUserWishlistIds` returns nil when userId is unavailable**
  - Given: `HomeViewModel 'home-ec1-noauth'` is initialized with no authenticated user (userId is nil or empty)
  - When: `startObservingWishlists()` is called
  - Then: `observeUserWishlistIds(onChange:)` returns `nil`, no Firestore snapshot listener is registered, and `myWishlists` / `myFriendWishlists` remain empty without crashing
  - Verify: Confirm the returned `ListenerRegistration?` is `nil`; confirm no Firestore network request is made; confirm the app does not crash or show an error dialog

### EC 2: Memory Leak Prevention — Listener Removed on Deinit

- [ ] **Scenario: `WishlistDetailViewController` removes Firestore listener on deallocation**
  - Given: `WishlistDetailViewController 'detail-ec2-deinit'` has an active Firestore listener registered via `startObservingWishlist(wishlistId:showInitialLoading:)`
  - When: The view model is deallocated (navigated away, strong reference released)
  - Then: `deinit` is called, `ListenerRegistration.remove()` is invoked exactly once, and no further snapshot callbacks are received after deallocation
  - Verify: Confirm `deinit` calls `.remove()` on the listener; confirm no crash or memory leak is reported by instruments after deallocation

- [ ] **Scenario: `HomeViewModel` removes Firestore listener on deallocation**
  - Given: `HomeViewModel 'home-ec2-deinit'` has an active Firestore listener registered via `startObservingWishlists()`
  - When: The view model is deallocated (user logs out or root is replaced)
  - Then: `deinit` is called, `ListenerRegistration.remove()` is invoked exactly once, and no further snapshot callbacks are received
  - Verify: Confirm `deinit` calls `.remove()` on the stored listener registration; confirm no retain cycle keeps the view model alive after navigation

### EC 3: Weak Self Capture — No Retain Cycle in Listener Callbacks

- [ ] **Scenario: Listener callback does not retain deallocated `HomeViewModel`**
  - Given: `HomeViewModel 'home-ec3-weakself'` registers a Firestore listener using `[weak self]` in the closure
  - When: The view model is released before a pending Firestore snapshot arrives and the snapshot callback fires
  - Then: The closure body is a no-op (guard let self exits early), and no crash or access-after-free occurs
  - Verify: Confirm `[weak self]` is present in the listener callback; confirm `guard let self` (or equivalent) exits gracefully when `self` is nil

### EC 4: Home Screen — No Loading Dialog on Subsequent Snapshots

- [ ] **Scenario: `isGettingList` stays false when data is already loaded and a new snapshot arrives**
  - Given: `HomeViewModel 'home-ec4-noloadingflash'` already has non-empty `myWishlists` and `myFriendWishlists` loaded from the first snapshot
  - When: A second Firestore snapshot fires (e.g., a new wishlist is joined by the user)
  - Then: `isGettingList` is NOT set to `true`; the full-screen loading dialog is NOT shown; `myWishlists` and `myFriendWishlists` are updated silently via `refreshWishlists()`
  - Verify: Assert `isGettingList` remains `false` throughout the second snapshot processing; confirm UI does not flash the loading state

### EC 5: Detail Screen — Loading Indicator Only When No Pre-loaded Wishlist

- [ ] **Scenario: No loading indicator when `WishlistModel` is pre-loaded from HomeView**
  - Given: `WishlistDetailScreen 'detail-ec5-preloaded'` is opened with a pre-loaded `WishlistModel` (navigated from HomeView)
  - When: `startObservingWishlist(wishlistId:showInitialLoading: false)` is called in `.task`
  - Then: `isShowLoading` is NOT set to `true`; the wishlist data from the pre-loaded model is immediately visible; the listener still registers and receives subsequent real-time updates
  - Verify: Confirm `showInitialLoading` is `false` when a `WishlistModel` is passed; confirm the loading spinner never appears during this navigation path

- [ ] **Scenario: Loading indicator shown when navigating via deep link with no pre-loaded wishlist**
  - Given: `WishlistDetailScreen 'detail-ec5-deeplink'` is opened via a route that only provides `wishlistId` (no `WishlistModel`)
  - When: `startObservingWishlist(wishlistId:showInitialLoading: true)` is called in `.task`
  - Then: `isShowLoading` is set to `true` immediately; a loading indicator is displayed; once the first Firestore snapshot arrives, `isShowLoading` is set to `false` and wishlist data is shown
  - Verify: Confirm `showInitialLoading` is `true` when no `WishlistModel` is pre-loaded; confirm the spinner appears and disappears at the correct lifecycle points

### EC 6: Wishlist ID Resolution — Missing or Ambiguous ID

- [ ] **Scenario: Wishlist ID resolved from `wishlistId` route parameter when `wishlist` is nil**
  - Given: `WishlistDetailScreen 'detail-ec6-routeid'` is initialized with `wishlistId = "wl-ec6-route"` and `wishlist = nil`
  - When: `.task` fires and `startObservingWishlist` is called
  - Then: The Firestore listener is registered against document path `wishList/wl-ec6-route`; real-time updates are received correctly
  - Verify: Confirm the resolved ID equals `"wl-ec6-route"` and that no nil-dereference or crash occurs

- [ ] **Scenario: Both `wishlistId` and `wishlist?.id` are nil — no listener registered**
  - Given: `WishlistDetailScreen 'detail-ec6-noid'` is initialized with both `wishlistId = nil` and `wishlist = nil`
  - When: `.task` fires and ID resolution is attempted
  - Then: `startObservingWishlist` is not called (or exits early); no Firestore listener is registered; the screen does not crash and may display an empty or error state
  - Verify: Confirm no unguarded force-unwrap or fatal error occurs; confirm no listener registration is attempted with an empty or invalid document path

### EC 7: Rapid Successive Snapshots — No UI State Corruption

- [ ] **Scenario: Multiple rapid Firestore snapshots arrive within the same render cycle**
  - Given: `WishlistDetailViewController 'detail-ec7-rapid'` has an active listener and is observing wishlist `"wl-ec7"`
  - When: Three Firestore snapshots fire in quick succession (e.g., item picked, then unpicked, then picked again within 500 ms)
  - Then: Each snapshot is processed sequentially; `wishlistInfo` reflects the state from the final snapshot; no intermediate states cause index-out-of-bounds or list corruption
  - Verify: Confirm the view model applies each update without crashing; confirm the final displayed state matches the last snapshot received

### EC 8: Firestore Listener Error Callback

- [ ] **Scenario: Firestore snapshot listener receives an error (network failure)**
  - Given: `WishlistDetailViewController 'detail-ec8-error'` has a registered Firestore listener and the device loses network connectivity mid-session
  - When: Firestore delivers an error to the snapshot callback instead of a document snapshot
  - Then: The error is handled gracefully; `wishlistInfo` retains its last known good state; `isShowLoading` is set to `false` if it was `true`; no crash occurs; the user is not shown a destructive error state
  - Verify: Confirm the listener callback guards against a non-nil error; confirm the last valid `wishlistInfo` is preserved and not cleared on error

### EC 9: Quick Navigation Away — Listener Removed Before First Snapshot

- [ ] **Scenario: User navigates away from `WishlistDetailScreen` before first Firestore snapshot arrives**
  - Given: `WishlistDetailScreen 'detail-ec9-quicknav'` registers a Firestore listener in `.task` with `showInitialLoading: true`
  - When: The user pops the screen within milliseconds of `.task` running, before any snapshot callback fires
  - Then: `deinit` is called, `ListenerRegistration.remove()` is invoked, and when the pending snapshot eventually arrives the `[weak self]` guard exits the closure safely with no crash or state mutation on the deallocated view model
  - Verify: Confirm the snapshot callback is a no-op after deallocation; confirm `isShowLoading` is not mutated after `deinit`; confirm no Firestore write or read is triggered post-deallocation
