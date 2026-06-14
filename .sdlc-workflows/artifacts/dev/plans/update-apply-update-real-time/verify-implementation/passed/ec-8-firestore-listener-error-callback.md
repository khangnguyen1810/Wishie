# EC 8: Firestore Listener Error Callback

- [x] **Scenario: Firestore snapshot listener receives an error (network failure)** ✅ RESOLVED
  - Given: `WishlistDetailViewController 'detail-ec8-error'` has a registered Firestore listener and the device loses network connectivity mid-session
  - When: Firestore delivers an error to the snapshot callback instead of a document snapshot
  - Then: The error is handled gracefully; `wishlistInfo` retains its last known good state; `isShowLoading` is set to `false` if it was `true`; no crash occurs; the user is not shown a destructive error state
  - Verify: Confirm the listener callback guards against a non-nil error; confirm the last valid `wishlistInfo` is preserved and not cleared on error
  - **Failure**: `isShowLoading` is never reset to `false` when a Firestore error arrives, and the error parameter is silently discarded without any explicit guard
  - **Root Cause**: In `WishlistService.observeWishlist(by:onChange:)`, the `addSnapshotListener` closure signature is `{ snapshot, _ in }` — the `Error?` parameter is discarded using `_`. On a network error, `snapshot?.data()` is `nil`, the `guard` fails, and `onChange` is never called. Since `isShowLoading = false` is set **only inside the `onChange` closure** within `startObservingWishlist`, it is never executed on the error path. If `showInitialLoading: true` was passed (e.g., navigating via deep-link route where `wishlist == nil`), `isShowLoading` is set to `true` at the start and remains `true` indefinitely, leaving the user stuck on a loading screen.
  - **Affected Files**:
    - `Wishie/Services/WishlistService.swift` line 381 — error parameter discarded: `addSnapshotListener { snapshot, _ in`
    - `Wishie/Services/WishlistService.swift` lines 382–384 — `onChange` never called on error path; no error handling branch exists
    - `Wishie/Screens/Detail/WishlistDetailViewController.swift` lines 45–56 — `isShowLoading = false` only inside the `onChange` closure; no fallback reset when `onChange` is not invoked
  - **Resolution Actions**:
    - Updated `WishlistServiceProtocol.observeWishlist` to add `onError: @escaping (Error) -> Void` parameter so the error path can be surfaced to callers
    - Updated `WishlistService.observeWishlist` to replace `{ snapshot, _ in }` with `{ snapshot, error in }`, guard against a non-nil `error` by calling `onError(error)` and returning early — `wishlistInfo` is never touched so it retains its last known good state
    - Updated `WishlistDetailViewController.startObservingWishlist` to provide an `onError` closure that executes `self.isShowLoading = false` on `@MainActor`, ensuring the loading state is always cleared regardless of whether the snapshot succeeds or fails
