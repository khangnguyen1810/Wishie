# AC 6: Member Gift Reservation Confirmation

- [x] **Scenario: Confirmation dialog appears when a member taps Reserve on an unpicked item** ✅ RESOLVED
  - Given: A wishlist `wishlist-ac6-reserve` exists; the logged-in user is a member (not the owner); an unpicked item `item-ac6-unpicked` is available
  - When: The member taps the item to open the bottom sheet and taps "Reserve"
  - Then: A confirmation dialog appears asking "Do you want to select this gift?" with "OK" and "Cancel" options before any backend action is taken
  - Verify: The dialog is displayed using the existing `showDialogIfNeeded` pattern; the `pickItem` service method is NOT called before the member confirms
  - **Failure**: The confirmation dialog is never visible to the user when Reserve is tapped inside the bottom sheet.
  - **Root Cause**: `reserveButton()` sets `viewModel.showReserveConfirmation = true` without dismissing the bottom sheet. The `showDialogIfNeeded($viewModel.showReserveConfirmation, ...)` modifier is applied only to the main body view (line 101–110 in `WishlistDetailScreen.swift`), not to the `bottomSheet()` view. In SwiftUI, a `.sheet` presentation creates a separate modal context that renders above the presenting view and all its `.overlay` / `showDialogIfNeeded` content. When `showReserveConfirmation = true` is triggered inside the still-open sheet, the dialog overlay exists on the presenting view underneath the sheet — it is not visible to the user. By contrast, the `showDeleteConfirmation` dialog is correctly applied to the bottom sheet itself (line 463–472), making it visible over the sheet.
  - **Affected Files**:
    - [Wishie/Screens/Detail/WishlistDetailScreen.swift](Wishie/Screens/Detail/WishlistDetailScreen.swift#L101) — `showDialogIfNeeded($viewModel.showReserveConfirmation, ...)` attached to main body only
    - [Wishie/Screens/Detail/WishlistDetailScreen.swift](Wishie/Screens/Detail/WishlistDetailScreen.swift#L506) — `reserveButton()` sets flag without sheet dismissal; no `showDialogIfNeeded` on `bottomSheet()` for reserve
  - **Resolution**: Removed `showDialogIfNeeded($viewModel.showReserveConfirmation, ...)` from the main body view modifiers and added it directly to the `bottomSheet()` view, after the existing `showDeleteConfirmation` modifier. The dialog now renders within the sheet's modal context and is visible to the user when Reserve is tapped.

- [x] **Scenario: Reservation is committed only after member confirms with OK** ✅ RESOLVED
  - Given: A wishlist `wishlist-ac6-confirm` exists; a member is viewing the bottom sheet for unpicked `item-ac6-to-pick`; the confirmation dialog is visible
  - When: The member taps "OK" in the confirmation dialog
  - Then: The `pickItem` backend service is called exactly once; the item's `isPicked` state updates to `true` in the UI; the progress bar increments
  - Verify: The item row reflects the picked state; the Reserve button is no longer active for that item; the progress label updates
  - **Failure**: The precondition "the confirmation dialog is visible" cannot be satisfied — the dialog is never shown above the bottom sheet (see Scenario 1 failure). The `onOk` handler that calls `pickItem` is therefore never reachable through the intended UI flow.
  - **Root Cause**: Cascades from Scenario 1. The `showDialogIfNeeded($viewModel.showReserveConfirmation, ...)` is not attached to `bottomSheet()`, so the OK action is inaccessible while the sheet is open. The underlying `onOk` implementation (`Task { viewModel.showBottomSheet = false; await viewModel.pickItem(wishlistId: wId) }` at line 106–108) and the subsequent `getWishlistInfo` refresh in `pickItem` are logically correct, but the entry point is unreachable.
  - **Affected Files**:
    - [Wishie/Screens/Detail/WishlistDetailScreen.swift](Wishie/Screens/Detail/WishlistDetailScreen.swift#L101) — `showDialogIfNeeded` for reserve not on `bottomSheet()`, blocking the OK confirmation path
  - **Resolution**: With `showDialogIfNeeded($viewModel.showReserveConfirmation, ...)` now attached to `bottomSheet()`, the OK action is reachable. The `onOk` handler (`Task { viewModel.showBottomSheet = false; let wId = ...; await viewModel.pickItem(wishlistId: wId) }`) was already logically correct and now executes correctly through the UI flow.

- [x] **Scenario: Reservation is cancelled without side effects when member taps Cancel** ✅ RESOLVED
  - Given: A wishlist `wishlist-ac6-cancel` exists; a member has triggered the reservation confirmation dialog for `item-ac6-cancel`
  - When: The member taps "Cancel" in the dialog
  - Then: The dialog dismisses; `item-ac6-cancel` remains unpicked; no backend call is made; the bottom sheet state is unchanged
  - Verify: The `pickItem` service method is not called; the progress bar count is unchanged; the item row still shows as unpicked
  - **Failure**: The confirmation dialog is never presented above the bottom sheet (see Scenario 1 failure), so the Cancel button is inaccessible. While the cancel path itself (`onCancel` is nil, so `DialogView` only dismisses `isShowDialog`) is logically correct and would not call `pickItem`, the entire dialog flow is unreachable via the UI.
  - **Root Cause**: Cascades from Scenario 1. `showDialogIfNeeded($viewModel.showReserveConfirmation, ...)` is missing from `bottomSheet()`. Cancel side-effect logic is correct in isolation but the dialog is never visible over the sheet.
  - **Affected Files**:
    - [Wishie/Screens/Detail/WishlistDetailScreen.swift](Wishie/Screens/Detail/WishlistDetailScreen.swift#L101) — `showDialogIfNeeded` for reserve not attached to `bottomSheet()`, making Cancel unreachable
  - **Resolution**: With the dialog now attached to `bottomSheet()`, Cancel is reachable. The cancel logic (`onCancel` is nil — `DialogView` only dismisses `isShowDialog`) was already correct; no `pickItem` call is made, and the bottom sheet and item state remain unchanged.
