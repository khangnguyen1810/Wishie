# Task 7: Wire confirmation dialogs for member reserve and owner delete

- [ ] 7.1: In `Wishie/Screens/Detail/WishlistDetailScreen.swift` UPDATE — `reserveButton()` `@ViewBuilder` method:
  - Replace the direct `await viewModel.pickItem(wishlistId:)` call inside `onTapGesture` with `viewModel.showReserveConfirmation = true` (only when `!viewModel.itemSelected.isPicked`). The actual `pickItem` call is triggered from the dialog's `onOk` closure (added in 7.2).

- [ ] 7.2: In `Wishie/Screens/Detail/WishlistDetailScreen.swift` UPDATE — `body` computed property:
  - Add a `showDialogIfNeeded` modifier for `$viewModel.showReserveConfirmation` chained after the existing `.showDialogIfNeeded($showLinkNotValidOrNotExist, ...)` modifier:
    - `title: "Reserve this gift?"`, `message: "Do you want to select this gift?"`, `showCancel: true`.
    - `onOk`: `{ Task { viewModel.showBottomSheet = false; let wId = viewModel.wishlistInfo.id; await viewModel.pickItem(wishlistId: wId) } }`.
    - `onCancel`: `nil` (dialog dismisses with no side effects).
  - Add a `showDialogIfNeeded` modifier for `$viewModel.showDeleteConfirmation` chained immediately after:
    - `title: "Delete item?"`, `message: "This action cannot be undone."`, `showCancel: true`.
    - `onOk`: `{ Task { viewModel.showBottomSheet = false; let wId = viewModel.wishlistInfo.id; await viewModel.deleteWishlistItem(wishlistId: wId) } }`.
    - `onCancel`: `nil`.
