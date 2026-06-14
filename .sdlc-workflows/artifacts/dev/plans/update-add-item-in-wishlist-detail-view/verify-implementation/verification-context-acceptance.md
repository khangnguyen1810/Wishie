# Verification Context — Acceptance Scenarios

## Purpose

Define testable acceptance scenarios in Given/When/Then format to verify the implementation meets functional requirements and success criteria.
This document serves as the single source of truth for acceptance verification.

## Verification Method

**Code review only.** All scenarios are verified by inspecting source code — no runtime execution required in this phase.

## Test Data Isolation

Each scenario uses unique, scenario-specific identifiers namespaced by AC category. No two scenarios share mutable state.

## Acceptance Scenarios:

### AC 1: FAB Owner Visibility

- [ ] **Scenario: Add item FAB renders only for wishlist owner**
  - Given: `WishlistDetailScreen` is loaded with wishlist data `'wishlist-ac1-owner'` where `wishlistInfo.isOwner()` returns `true`
  - When: The screen's view hierarchy is reviewed
  - Then: The "Add item" floating action button is conditionally present, gated by `viewModel.wishlistInfo.isOwner()`
  - Verify: Code review confirms the FAB is wrapped in an `if viewModel.wishlistInfo.isOwner()` guard; no FAB code path exists outside this guard

- [ ] **Scenario: Add item FAB is absent for non-owner viewer**
  - Given: `WishlistDetailScreen` is loaded with wishlist data `'wishlist-ac1-viewer'` where `wishlistInfo.isOwner()` returns `false`
  - When: The screen's view hierarchy is reviewed
  - Then: No FAB or add-item entry point is rendered
  - Verify: Code review confirms there is no unconditional FAB render or alternative add-item trigger available to non-owners

### AC 2: Add Item Option Sheet Presentation

- [ ] **Scenario: Tapping the FAB presents AddItemOptionSheet**
  - Given: The "Add item" FAB is visible for wishlist `'wishlist-ac2-sheet'` (user is owner)
  - When: The FAB's action handler is reviewed
  - Then: The action sets a `showAddItemOptionSheet` (or equivalent) state flag to `true`, which is bound to `AddItemOptionSheet` via a `.sheet` modifier
  - Verify: Code review confirms FAB action exclusively toggles the option sheet flag; `AddItemOptionSheet` is not constructed inline in the FAB body

### AC 3: Manual Entry Sheet Presentation

- [ ] **Scenario: Selecting "Fill in manually" dismisses option sheet then presents AddItemManualDetailSheet**
  - Given: `AddItemOptionSheet` is displayed for wishlist `'wishlist-ac3-manual'`
  - When: The "Fill in manually" callback in the option sheet is triggered
  - Then: The option sheet is dismissed first (via `showAddItemOptionSheet = false`), then `AddItemManualDetailSheet` is presented after a `DispatchQueue.main.asyncAfter` delay consistent with the existing `showDeleteConfirmation` pattern
  - Verify: Code review confirms the sequential dismiss-then-present pattern using `asyncAfter`; `AddItemManualDetailSheet` contains fields for item name (required), description, image (`ImagePickerBox`), and product link (optional)

### AC 4: Paste Link Sheet Presentation

- [ ] **Scenario: Selecting "Paste a product link" dismisses option sheet then presents AddItemPasteLinkDetailSheet**
  - Given: `AddItemOptionSheet` is displayed for wishlist `'wishlist-ac4-paste'`
  - When: The "Paste a product link" callback is triggered
  - Then: The option sheet is dismissed and `AddItemPasteLinkDetailSheet` is presented after the same `asyncAfter` delay, containing a URL input field, a fetch action via `ProductMetadataService`, a metadata preview section, and an "Add to wishlist" confirm button
  - Verify: Code review confirms the dismiss-before-present pattern and that `AddItemPasteLinkDetailSheet` exposes all required UI elements bound to `viewModel` state

### AC 5: Item Name Validation

- [ ] **Scenario: Add button is disabled when item name is empty**
  - Given: `AddItemManualDetailSheet` is presented for item `'item-ac5-validation'` with `newItemName` bound to an empty string
  - When: The "Add" button's enabled/disabled logic is reviewed
  - Then: The `WishieButton` for the add action is disabled (e.g., `.disabled(viewModel.newItemName.trimmingCharacters(in: .whitespaces).isEmpty)`)
  - Verify: Code review confirms the disabled modifier is applied to the `WishieButton`, not a custom overlay, and correctly reflects `newItemName` being blank

- [ ] **Scenario: Add button becomes enabled when a valid item name is entered**
  - Given: `AddItemManualDetailSheet` is presented for item `'item-ac5-valid'` with `newItemName` bound to a non-empty string
  - When: The button's disabled condition is evaluated
  - Then: The `WishieButton` is in an enabled state allowing the add action to proceed
  - Verify: Code review confirms the same disabled modifier evaluates to `false` when `newItemName` contains at least one non-whitespace character

### AC 6: Image Upload Before Persistence

- [ ] **Scenario: Image upload precedes Firestore item creation when an image is selected**
  - Given: A user has selected an image in `AddItemManualDetailSheet` for item `'item-ac6-image'` and entered a valid name
  - When: The add action method in `WishlistDetailViewController` is reviewed
  - Then: `WishlistService.upload(image:fileName:)` is called first, and `WishlistService.addWishlistItem(wishlistId:item:)` is only called upon a successful upload result; an upload failure stops execution and surfaces an error
  - Verify: Code review confirms the sequential `async/await` or callback chain with upload as a prerequisite; no path exists where `addWishlistItem` is called when upload has failed

### AC 7: Item Persistence via WishlistService

- [ ] **Scenario: addWishlistItem is called with correct wishlistId and constructed item**
  - Given: All required fields are filled for item `'item-ac7-persist'` in `WishlistDetailViewController`
  - When: The add action method is reviewed
  - Then: `WishlistService.addWishlistItem(wishlistId:item:)` is called with the current wishlist's ID and a `WishlistItem` constructed from `newItemName`, `newItemDescription`, the uploaded image URL, and `newItemLink`
  - Verify: Code review confirms the `WishlistItem` model is populated from `viewModel` state properties before being passed to the service, with no hard-coded or placeholder values

### AC 8: State Reset After Successful Add

- [ ] **Scenario: All new-item state properties are reset after a successful add**
  - Given: An item `'item-ac8-reset'` has been successfully added (both upload and `addWishlistItem` completed without error)
  - When: The success path of the add action in `WishlistDetailViewController` is reviewed
  - Then: `newItemName`, `newItemDescription`, `newItemImage`, `newItemLink`, and `metadataFetchError` are all reset to their default empty/nil values in the same success branch
  - Verify: Code review confirms all five state properties are explicitly reset; no property is left stale after a successful operation

### AC 9: Error Surfacing via ViewModel

- [ ] **Scenario: Errors during add flow are surfaced through isShowError and errorMessage**
  - Given: An error occurs during image upload or `addWishlistItem` for item `'item-ac9-error'`
  - When: The error handling (catch blocks or failure callbacks) in `WishlistDetailViewController` is reviewed
  - Then: `isShowError` is set to `true` and `errorMessage` is populated with a descriptive, non-empty error string in every failure path of the add operation
  - Verify: Code review confirms both `isShowError` and `errorMessage` are set together in each catch block; neither is set in isolation

### AC 10: MVVM Compliance — Business Logic in ViewController

- [ ] **Scenario: New sheets delegate all async and business logic to WishlistDetailViewController**
  - Given: Source code of `AddItemManualDetailSheet` and `AddItemPasteLinkDetailSheet` for feature `'feature-ac10-mvvm'`
  - When: The view files are reviewed for any direct service calls or async operations
  - Then: Both views contain only layout and user interaction code; all service calls (`WishlistService`, `ProductMetadataService`), state mutations, and async operations are implemented as methods on `WishlistDetailViewController`
  - Verify: Code review confirms views receive `viewModel: WishlistDetailViewController` (or equivalent `@ObservedObject`) and invoke `viewModel.someMethod()` for actions rather than performing work inline

### AC 11: AddItemOptionSheet Reused Without Modification

- [ ] **Scenario: Existing AddItemOptionSheet component is reused unchanged**
  - Given: The file `Wishie/Screens/CreateList/AddItemOptionSheet.swift` exists prior to this implementation
  - When: The file diff and its usage in `WishlistDetailScreen` are reviewed
  - Then: The `AddItemOptionSheet` source file has no modifications, and the call site in `WishlistDetailScreen` passes arguments that match the component's declared interface
  - Verify: Code review confirms zero changes to `AddItemOptionSheet.swift`; parameter labels and types at the call site match the component's original signature exactly
