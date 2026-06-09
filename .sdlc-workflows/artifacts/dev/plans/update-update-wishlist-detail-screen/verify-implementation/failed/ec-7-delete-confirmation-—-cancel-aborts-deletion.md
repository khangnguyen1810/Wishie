# EC 7: Delete Confirmation — Cancel Aborts Deletion

- [x] **Scenario: Tapping Cancel on the delete confirmation dialog leaves the item intact** ✅ RESOLVED
  - Given: Wishlist `"wishlist-ec7-canceldelete"` has item `"item-ec7-target"` with `isPicked = false`; the owner opens the bottom sheet for this item
  - When: The owner taps "Delete" and then taps "Cancel" on the confirmation dialog
  - Then: The item is NOT removed from the list; no backend `deleteWishlistItem` call is made
  - Verify: `"item-ec7-target"` remains visible in the list with no visual artifact; the progress bar value is unchanged; the bottom sheet is dismissed cleanly
  - **Resolution**: Added `onCancel: { viewModel.showBottomSheet = false }` to both `showDialogIfNeeded` calls for `showDeleteConfirmation` in `WishlistDetailScreen.swift` — the main-view delete dialog (L108-L114) and the bottom-sheet delete dialog (L471-L482). When Cancel is tapped, `DialogView` now executes the `onCancel` closure which sets `showBottomSheet = false`, dismissing the bottom sheet cleanly alongside the dialog.
  - **Affected Files**:
    - [Wishie/Screens/Detail/WishlistDetailScreen.swift](../../../../../../../../Wishie/Screens/Detail/WishlistDetailScreen.swift#L108-L114) — added `onCancel` closure to main-view delete dialog
    - [Wishie/Screens/Detail/WishlistDetailScreen.swift](../../../../../../../../Wishie/Screens/Detail/WishlistDetailScreen.swift#L471-L482) — added `onCancel` closure to bottom-sheet delete dialog
