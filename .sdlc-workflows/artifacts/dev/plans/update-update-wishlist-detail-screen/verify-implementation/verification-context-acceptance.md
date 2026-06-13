# Verification Context — Acceptance Scenarios

## Purpose

Define testable acceptance scenarios in Given/When/Then format to verify the implementation meets functional requirements and success criteria.
This document serves as the single source of truth for acceptance verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "user-ac1-login", "product-ac2-checkout"). No two scenarios should share mutable state.

## Acceptance Scenarios:

---

### AC 1: Gift Selection Progress Indicator

- [ ] **Scenario: Progress bar displays correct fill and label when some items are picked**
  - Given: A wishlist `wishlist-ac1-progress` exists with 7 items total, 3 of which have `isPicked = true`
  - When: The owner or a member navigates to the WishlistDetail screen for `wishlist-ac1-progress`
  - Then: A horizontal progress bar appears in the header with fill ratio 3/7 and a text label reading "3 / 7 gifts selected"
  - Verify: The progress bar fill visually represents ~42.8% width; the label text matches the exact format "X / Y gifts selected"; the element is visible above the item list without being clipped

- [ ] **Scenario: Progress bar updates after a member reserves an item**
  - Given: A wishlist `wishlist-ac1-reserve-update` exists with 5 items, 2 of which are already picked; a member is viewing the detail screen showing "2 / 5 gifts selected"
  - When: The member selects an unpicked item, confirms the reservation dialog with "OK", and the backend call succeeds
  - Then: The progress bar fill and label update to "3 / 5 gifts selected" without requiring a manual screen refresh
  - Verify: The progress bar re-renders automatically; the fill increases; the numeric label reflects the new count

- [ ] **Scenario: Progress bar updates after the owner deletes an item**
  - Given: A wishlist `wishlist-ac1-delete-update` exists with 6 items, 2 picked; the owner is viewing the detail screen showing "2 / 6 gifts selected"
  - When: The owner deletes one unpicked item and confirms the deletion dialog
  - Then: The progress bar fill and label update to "2 / 5 gifts selected"
  - Verify: Total count decreases by 1; picked count remains unchanged; bar fill ratio recalculates correctly

---

### AC 2: Most Desired Item Marking — Owner Bottom Sheet CTA

- [ ] **Scenario: "Mark as Most Desired" CTA appears for an unmarked item in the owner's bottom sheet**
  - Given: A wishlist `wishlist-ac2-markdesired` is owned by the logged-in user and contains item `item-ac2-unmarked` with `isMostDesired = false`
  - When: The owner taps on `item-ac2-unmarked` to open the bottom sheet
  - Then: A "Mark as Most Desired" button is visible in the bottom sheet
  - Verify: The CTA is tappable; no star badge is shown on the item row before tapping; the button label matches the specified text

- [ ] **Scenario: "Mark as Most Desired" CTA is absent when the item is already marked**
  - Given: A wishlist `wishlist-ac2-alreadydesired` is owned by the logged-in user and contains item `item-ac2-marked` with `isMostDesired = true`
  - When: The owner taps on `item-ac2-marked` to open the bottom sheet
  - Then: The "Mark as Most Desired" CTA is not shown in the bottom sheet
  - Verify: The bottom sheet renders without the CTA; other CTAs (Edit, Delete) are unaffected

- [ ] **Scenario: Marking an item as most desired persists and does not affect other items**
  - Given: A wishlist `wishlist-ac2-multidesired` is owned by the logged-in user and contains `item-ac2-a` (`isMostDesired = false`) and `item-ac2-b` (`isMostDesired = false`)
  - When: The owner marks `item-ac2-a` as most desired via the bottom sheet
  - Then: `item-ac2-a` shows a star badge; `item-ac2-b` remains unchanged with no star badge; the change persists to Firestore
  - Verify: Both items are visible in the list; only `item-ac2-a` has the star badge; re-opening the screen still reflects the updated state

---

### AC 3: Star Badge Display on Most Desired Items

- [ ] **Scenario: Star badge is visible on item rows where isMostDesired is true**
  - Given: A wishlist `wishlist-ac3-starbadge` contains three items: `item-ac3-desired` (`isMostDesired = true`), `item-ac3-plain` (`isMostDesired = false`), `item-ac3-picked` (`isMostDesired = false`, `isPicked = true`)
  - When: Any user (owner or member) views the WishlistDetail screen
  - Then: A star badge is rendered on the row for `item-ac3-desired` only
  - Verify: Star badge is absent on `item-ac3-plain` and `item-ac3-picked`; the badge does not overlap or truncate the item title or image; the layout is correct on both standard and large dynamic type sizes

- [ ] **Scenario: Wishlist items are displayed fully and correctly without any UI errors**
  - Given: A wishlist `wishlist-ac3-fullrender` contains 10 items with varying combinations of `isMostDesired`, `isPicked`, long titles (>40 characters), and items with and without images
  - When: The owner navigates to the WishlistDetail screen
  - Then: All 10 items are visible in the list, each displaying its title, image placeholder or thumbnail, star badge (if applicable), and picked indicator without clipping, overlap, or misalignment
  - Verify: No item row is cut off at the list boundaries; scrolling reveals all items; the star badge, picked state indicator, and text labels co-exist without visual collision; no runtime UI warnings or layout constraint errors are produced

---

### AC 4: Owner Delete Item via Bottom Sheet

- [ ] **Scenario: Delete button is present for an unpicked item in the owner's bottom sheet**
  - Given: A wishlist `wishlist-ac4-delete` is owned by the logged-in user and contains an unpicked item `item-ac4-unpicked` (`isPicked = false`)
  - When: The owner taps `item-ac4-unpicked` to open the bottom sheet
  - Then: A "Delete" button is visible and enabled in the bottom sheet
  - Verify: The button is tappable; it is styled as a destructive action (e.g., red text or icon)

- [ ] **Scenario: Delete button is hidden or disabled for an already-picked item**
  - Given: A wishlist `wishlist-ac4-picked-guard` is owned by the logged-in user and contains a picked item `item-ac4-picked` (`isPicked = true`)
  - When: The owner taps `item-ac4-picked` to open the bottom sheet
  - Then: The "Delete" button is hidden or disabled
  - Verify: The owner cannot initiate a delete action on the picked item; other bottom sheet content remains visible

- [ ] **Scenario: Deletion confirmation dialog appears and item is removed on confirm**
  - Given: A wishlist `wishlist-ac4-confirm-delete` is owned by the logged-in user and contains unpicked item `item-ac4-to-delete`; the owner has opened the bottom sheet for that item
  - When: The owner taps "Delete" in the bottom sheet
  - Then: A confirmation dialog appears; upon tapping "OK", the item is removed from the list and deleted from Firestore; the progress bar updates accordingly
  - Verify: The dialog uses the existing `showDialogIfNeeded` pattern; the item row disappears from the list after confirmation; the backend `deleteWishlistItem` call is made exactly once

---

### AC 5: Owner Swipe-to-Delete

- [ ] **Scenario: Swipe-to-delete action is available on unpicked item rows for the owner**
  - Given: A wishlist `wishlist-ac5-swipe` is owned by the logged-in user and contains an unpicked item `item-ac5-swipeable`
  - When: The owner swipes left on the row for `item-ac5-swipeable`
  - Then: A destructive "Delete" swipe action button is revealed
  - Verify: The swipe action is implemented via native SwiftUI `List` `.swipeActions`; the action button is labeled "Delete" with a destructive style; items implemented as a `List` not a `ForEach`-in-`VStack`

- [ ] **Scenario: Swipe-to-delete triggers confirmation dialog before deletion**
  - Given: A wishlist `wishlist-ac5-swipe-confirm` is owned by the logged-in user; the owner has swiped to reveal the "Delete" action on `item-ac5-confirm`
  - When: The owner taps the "Delete" swipe action button
  - Then: A confirmation dialog is presented before any backend call is made; confirming deletes the item; canceling dismisses the dialog with no changes
  - Verify: The dialog appears before `deleteWishlistItem` is called; item remains in the list if the user cancels

---

### AC 6: Member Gift Reservation Confirmation

- [ ] **Scenario: Confirmation dialog appears when a member taps Reserve on an unpicked item**
  - Given: A wishlist `wishlist-ac6-reserve` exists; the logged-in user is a member (not the owner); an unpicked item `item-ac6-unpicked` is available
  - When: The member taps the item to open the bottom sheet and taps "Reserve"
  - Then: A confirmation dialog appears asking "Do you want to select this gift?" with "OK" and "Cancel" options before any backend action is taken
  - Verify: The dialog is displayed using the existing `showDialogIfNeeded` pattern; the `pickItem` service method is NOT called before the member confirms

- [ ] **Scenario: Reservation is committed only after member confirms with OK**
  - Given: A wishlist `wishlist-ac6-confirm` exists; a member is viewing the bottom sheet for unpicked `item-ac6-to-pick`; the confirmation dialog is visible
  - When: The member taps "OK" in the confirmation dialog
  - Then: The `pickItem` backend service is called exactly once; the item's `isPicked` state updates to `true` in the UI; the progress bar increments
  - Verify: The item row reflects the picked state; the Reserve button is no longer active for that item; the progress label updates

- [ ] **Scenario: Reservation is cancelled without side effects when member taps Cancel**
  - Given: A wishlist `wishlist-ac6-cancel` exists; a member has triggered the reservation confirmation dialog for `item-ac6-cancel`
  - When: The member taps "Cancel" in the dialog
  - Then: The dialog dismisses; `item-ac6-cancel` remains unpicked; no backend call is made; the bottom sheet state is unchanged
  - Verify: The `pickItem` service method is not called; the progress bar count is unchanged; the item row still shows as unpicked
