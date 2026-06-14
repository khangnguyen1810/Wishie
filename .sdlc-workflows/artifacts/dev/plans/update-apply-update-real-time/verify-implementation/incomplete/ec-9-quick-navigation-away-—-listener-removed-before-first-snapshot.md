# EC 9: Quick Navigation Away — Listener Removed Before First Snapshot

- [x] **Scenario: User navigates away from `WishlistDetailScreen` before first Firestore snapshot arrives**
  - Given: `WishlistDetailScreen 'detail-ec9-quicknav'` registers a Firestore listener in `.task` with `showInitialLoading: true`
  - When: The user pops the screen within milliseconds of `.task` running, before any snapshot callback fires
  - Then: `deinit` is called, `ListenerRegistration.remove()` is invoked, and when the pending snapshot eventually arrives the `[weak self]` guard exits the closure safely with no crash or state mutation on the deallocated view model
  - Verify: Confirm the snapshot callback is a no-op after deallocation; confirm `isShowLoading` is not mutated after `deinit`; confirm no Firestore write or read is triggered post-deallocation
