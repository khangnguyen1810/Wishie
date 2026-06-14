# Verification Context — Edge Case Scenarios

## Purpose

Define testable edge case scenarios in Given/When/Then format to verify the implementation handles boundary conditions, error states, and non-functional requirements.
This document serves as the single source of truth for edge case verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "cart-ec1-empty", "user-ec2-locked"). No two scenarios should share mutable state.

## Edge Case Scenarios:

> **Scope Note:** Verification in this phase is code review only. Each scenario is verified by inspecting implementation code rather than executing the app.

---

### EC 1: Item Name Validation — Empty Input

- [ ] **Scenario: Add button is disabled when item name is empty**
  - Given: `AddItemManualDetailSheet` is presented with `newItemName` bound to an empty string `""`
  - When: The user has not entered any text in the item name field
  - Then: The primary "Add" `WishieButton` remains disabled and cannot be tapped
  - Verify: Confirm the button's `disabled` modifier or `isEnabled` condition evaluates `newItemName.isEmpty` and blocks the action

- [ ] **Scenario: Add button remains disabled for whitespace-only item name**
  - Given: `AddItemManualDetailSheet` is presented with `newItemName` bound to `"   "` (whitespace only)
  - When: The user has entered only whitespace characters in the item name field
  - Then: The primary "Add" `WishieButton` remains disabled
  - Verify: Confirm the validation trims whitespace (e.g., `newItemName.trimmingCharacters(in: .whitespaces).isEmpty`) before enabling the button

---

### EC 2: Ownership Check — Non-Owner View

- [ ] **Scenario: Add item FAB is hidden for non-owner viewers**
  - Given: `WishlistDetailScreen` is displayed for wishlist `"wishlist-ec2-nonowner"` where `viewModel.wishlistInfo.isOwner()` returns `false`
  - When: The screen finishes loading and renders the item list
  - Then: The floating action button for adding items is not visible in the view hierarchy
  - Verify: Confirm the FAB rendering is gated on `viewModel.wishlistInfo.isOwner()` returning `true`

---

### EC 3: Sheet Stacking — Sequential Presentation Delay

- [ ] **Scenario: Option sheet dismisses before manual entry sheet is presented**
  - Given: `AddItemOptionSheet` is currently presented on `WishlistDetailScreen`
  - When: The user taps "Fill in manually"
  - Then: `AddItemOptionSheet` is dismissed first, followed by a `DispatchQueue.main.asyncAfter` delay before `AddItemManualDetailSheet` is presented, preventing iOS sheet-stack conflicts
  - Verify: Confirm the view model or action handler sets the option sheet binding to `false` and then uses `asyncAfter` before setting the manual sheet binding to `true`

- [ ] **Scenario: Option sheet dismisses before paste-link sheet is presented**
  - Given: `AddItemOptionSheet` is currently presented on `WishlistDetailScreen`
  - When: The user taps "Paste a product link"
  - Then: `AddItemOptionSheet` is dismissed first with a delay before `AddItemPasteLinkDetailSheet` is presented
  - Verify: Confirm the same `asyncAfter` dismiss-then-present pattern is applied for the paste-link entry path

---

### EC 4: Image Upload Failure

- [ ] **Scenario: Wishlist item is not persisted when image upload fails**
  - Given: `AddItemManualDetailSheet` has `newItemName` set to `"item-ec4-uploadfail"` and a selected image in `newItemImage`
  - When: `WishlistService.upload(image:fileName:)` throws or returns an error during the add flow
  - Then: `WishlistService.addWishlistItem(wishlistId:item:)` is never called, and `isShowError` is set to `true` with a relevant `errorMessage`
  - Verify: Confirm the ViewController's add logic awaits the upload result and only proceeds to `addWishlistItem` on success; an error short-circuits to the error state

---

### EC 5: Firestore Persistence Failure After Successful Image Upload

- [ ] **Scenario: Error is surfaced when Firestore add fails after image is already uploaded**
  - Given: `WishlistService.upload(image:fileName:)` succeeds for wishlist item `"item-ec5-fsfail"` and returns a valid image URL
  - When: `WishlistService.addWishlistItem(wishlistId:item:)` throws or returns an error
  - Then: `isShowError` is set to `true` with a relevant `errorMessage`; new-item state is NOT reset (preserving user input for retry)
  - Verify: Confirm the error branch in the ViewController sets the error state and does not invoke the state-reset logic

---

### EC 6: Product Metadata Fetch Failure

- [ ] **Scenario: Metadata fetch error is surfaced in paste-link sheet without blocking dismissal**
  - Given: `AddItemPasteLinkDetailSheet` is presented with a URL input of `"https://invalid-ec6.example.com"`
  - When: `ProductMetadataService` fetch call fails (network error or non-parseable response)
  - Then: `metadataFetchError` is set with an error message visible in the sheet; the "Add to wishlist" confirm action remains unavailable until valid metadata is fetched
  - Verify: Confirm `metadataFetchError` binding is set on fetch failure and the confirm button is disabled while `metadataFetchError` is non-nil or metadata is absent

---

### EC 7: State Reset — Post-Successful Add

- [ ] **Scenario: All new-item state fields are cleared after a successful item add**
  - Given: A successful add flow completes for item `"item-ec7-reset"` with name, description, image, and link all populated
  - When: `WishlistService.addWishlistItem` returns successfully
  - Then: `newItemName`, `newItemDescription`, `newItemImage`, `newItemLink`, and `metadataFetchError` are all reset to their initial/empty values
  - Verify: Confirm the post-success code path in the ViewController explicitly resets each of these five state properties
