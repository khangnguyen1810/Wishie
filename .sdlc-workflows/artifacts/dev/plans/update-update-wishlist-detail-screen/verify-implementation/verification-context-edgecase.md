# Verification Context — Edge Case Scenarios

## Purpose

Define testable edge case scenarios in Given/When/Then format to verify the implementation handles boundary conditions, error states, and non-functional requirements.
This document serves as the single source of truth for edge case verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "cart-ec1-empty", "user-ec2-locked"). No two scenarios should share mutable state.

## Edge Case Scenarios:

### EC 1: Progress Indicator — Zero Items

- [ ] **Scenario: Progress bar renders without divide-by-zero when wishlist is empty**
  - Given: Wishlist `"wishlist-ec1-empty"` exists with `0` items and an owner is viewing the detail screen
  - When: The `WishlistDetailScreen` header loads
  - Then: The progress bar displays without a crash or NaN/Inf fill value, and the label shows `"0 / 0 gifts selected"` or a safe empty-state message
  - Verify: No runtime exception is thrown; the progress bar fill remains at `0.0`; the header layout is not broken or clipped

### EC 2: Progress Indicator — All Items Picked

- [ ] **Scenario: Progress bar reaches 100% fill when every item is reserved**
  - Given: Wishlist `"wishlist-ec2-allpicked"` has `5` items and all `5` have `isPicked = true`
  - When: A member or owner views the `WishlistDetailScreen`
  - Then: The progress bar is completely filled and the label reads `"5 / 5 gifts selected"`
  - Verify: The bar fill value equals `1.0`; the label text is fully visible without truncation; no UI overflow or clipping occurs

### EC 3: isMostDesired Data Migration — Legacy Item Lacking Field

- [ ] **Scenario: Existing Firestore item without `isMostDesired` field defaults to false**
  - Given: Wishlist `"wishlist-ec3-legacy"` contains item `"item-ec3-nofield"` whose Firestore document has no `isMostDesired` key
  - When: The item is fetched and decoded into `WishlistItem`
  - Then: `isMostDesired` is `false`; no star badge appears on the item row; no decode error or crash occurs
  - Verify: The item row renders fully and correctly; the owner's bottom sheet does not pre-check "Mark as Most Desired"

### EC 4: isMostDesired Toggle — All Items Marked

- [ ] **Scenario: Every item in a wishlist can be independently marked as most desired simultaneously**
  - Given: Wishlist `"wishlist-ec4-allstar"` has `3` items `"item-ec4-a"`, `"item-ec4-b"`, `"item-ec4-c"`, all with `isMostDesired = false`
  - When: The owner marks each item as most desired one by one via the bottom sheet
  - Then: All three items display a star badge; marking one item does not remove the badge from previously marked items
  - Verify: Each item row renders its star badge without layout overlap, truncation, or misalignment; the list scrolls smoothly

### EC 5: Delete Protection — Picked Item via Bottom Sheet

- [ ] **Scenario: Delete CTA is hidden when the selected item is already reserved**
  - Given: Wishlist `"wishlist-ec5-picked"` has item `"item-ec5-reserved"` with `isPicked = true`; the owner is viewing the detail screen
  - When: The owner taps on `"item-ec5-reserved"` to open the bottom sheet
  - Then: The "Delete" button is hidden or disabled in the bottom sheet
  - Verify: No delete action can be triggered; the bottom sheet still displays other available CTAs correctly without layout gaps

### EC 6: Delete Protection — Picked Item via Swipe

- [ ] **Scenario: Swipe-to-delete is suppressed on an already-reserved item row**
  - Given: Wishlist `"wishlist-ec6-swipe"` has item `"item-ec6-reserved"` with `isPicked = true`; the owner is viewing the native SwiftUI `List`
  - When: The owner performs a leading or trailing swipe gesture on `"item-ec6-reserved"`
  - Then: No delete swipe action appears; the swipe gesture is ignored or dismissed
  - Verify: The item row remains fully visible and correctly rendered after the swipe attempt; no accidental deletion occurs

### EC 7: Delete Confirmation — Cancel Aborts Deletion

- [ ] **Scenario: Tapping Cancel on the delete confirmation dialog leaves the item intact**
  - Given: Wishlist `"wishlist-ec7-canceldelete"` has item `"item-ec7-target"` with `isPicked = false`; the owner opens the bottom sheet for this item
  - When: The owner taps "Delete" and then taps "Cancel" on the confirmation dialog
  - Then: The item is NOT removed from the list; no backend `deleteWishlistItem` call is made
  - Verify: `"item-ec7-target"` remains visible in the list with no visual artifact; the progress bar value is unchanged; the bottom sheet is dismissed cleanly

### EC 8: Member Reservation Confirmation — Cancel Has No Side Effects

- [ ] **Scenario: Tapping Cancel on the reservation confirmation dialog does not reserve the item**
  - Given: Wishlist `"wishlist-ec8-cancelreserve"` has item `"item-ec8-free"` with `isPicked = false`; a member is viewing the detail screen
  - When: The member taps "Reserve" on `"item-ec8-free"` and then taps "Cancel" on the confirmation dialog
  - Then: `isPicked` remains `false`; `pickItem` backend service is NOT called; the progress bar value does not change
  - Verify: The item row renders as unreserved; the dialog is dismissed without any state mutation; the member can re-tap "Reserve" without issues

### EC 9: Item List Full Display — Long Item Names Without UI Errors

- [ ] **Scenario: Item rows with very long names and notes display fully without truncation or layout breakage**
  - Given: Wishlist `"wishlist-ec9-longtext"` has item `"item-ec9-longname"` with a name of 120 characters and a note of 300 characters; `isMostDesired = true`
  - When: The owner views the `WishlistDetailScreen` item list
  - Then: The item name is displayed completely or gracefully truncated per design spec; the star badge remains correctly positioned; no row height collapses to zero or expands beyond screen bounds
  - Verify: All text is legible; the star badge does not overlap item text; the row does not clip the image thumbnail; the list scrolls without jank

### EC 10: Member Cannot Reserve an Already-Picked Item

- [ ] **Scenario: Reserve button is non-interactive for an item already picked by another member**
  - Given: Wishlist `"wishlist-ec10-alreadypicked"` has item `"item-ec10-taken"` with `isPicked = true` and `pickedUserId` set to a different user
  - When: A different member views the detail screen and taps on `"item-ec10-taken"`
  - Then: The "Reserve" button is disabled or not shown in the bottom sheet; no confirmation dialog is presented
  - Verify: No backend call is made; the bottom sheet displays the item's reserved state clearly without UI errors
