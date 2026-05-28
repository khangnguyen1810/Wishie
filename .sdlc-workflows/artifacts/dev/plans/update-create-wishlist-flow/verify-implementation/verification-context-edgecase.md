# Verification Context — Edge Case Scenarios

## Purpose

Define testable edge case scenarios in Given/When/Then format to verify the implementation handles boundary conditions, error states, and non-functional requirements.
This document serves as the single source of truth for edge case verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "cart-ec1-empty", "user-ec2-locked"). No two scenarios should share mutable state.

## Edge Case Scenarios:

### EC 1: Extreme Aspect Ratio Image — Portrait

- [ ] **Scenario: Portrait image with 3:16 aspect ratio renders within fixed frame without overflow**
  - Given: WishlistItemCard 'item-ec1-portrait' has a very tall portrait image (3:16 aspect ratio) selected as its photo
  - When: The card renders inside the item list
  - Then: The image fills the fixed frame (`maxWidth: .infinity`, `minHeight: 180`) using `.scaledToFill()`, is fully clipped by `clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))`, and does not overflow the card bounds or cause layout shifts
  - Verify: Inspect the rendered card in both light and dark mode at standard iPhone sizes; confirm no image content bleeds outside the rounded rectangle boundary

### EC 2: Extreme Aspect Ratio Image — Landscape

- [ ] **Scenario: Wide landscape image with 16:3 aspect ratio renders without vertical overflow**
  - Given: WishlistItemCard 'item-ec2-landscape' has a very wide landscape image (16:3 aspect ratio) selected as its photo
  - When: The card renders inside the item list
  - Then: The image fills the fixed frame respecting `minHeight: 180`, is clipped to `RoundedRectangle(cornerRadius: 12, style: .continuous)`, and does not collapse to zero height or produce a layout break
  - Verify: Measure the rendered image area height; confirm it is at least 180pt and the card height is stable across re-renders

### EC 3: No Image Selected — Placeholder State

- [ ] **Scenario: Card with no image selected shows centered upload placeholder**
  - Given: WishlistItemCard 'item-ec3-noimage' has no image selected (image binding is nil)
  - When: The card renders
  - Then: The image area displays the `Image("upload")` icon and an "Add photo" label centered within the fixed frame (`minHeight: 180`), and no crash or blank space occurs
  - Verify: Confirm the placeholder is vertically and horizontally centered within the frame; confirm tapping the area opens the image picker

### EC 4: Keyboard Toolbar "Done" on itemLink Field

- [ ] **Scenario: Tapping Done while itemLink field is focused dismisses the keyboard**
  - Given: WishlistItemCard 'item-ec4-linkfocus' has its `itemLink` text field focused (not `name` or `description`)
  - When: The user taps the "Done" button on the keyboard toolbar
  - Then: `focusedField` is set to `nil`, the keyboard dismisses, and no other field on the card gains focus
  - Verify: After tapping Done, confirm no text field retains first responder status on 'item-ec4-linkfocus'

### EC 5: Keyboard Toolbar Isolation Across Multiple Cards

- [ ] **Scenario: Done toolbar button on card 2 does not affect cards 1 and 3**
  - Given: Wishlist 'wishlist-ec5-multi' contains exactly 3 WishlistItemCards; the `name` field of card 2 is currently focused
  - When: The user taps the "Done" button on the keyboard toolbar
  - Then: Only card 2's keyboard dismisses; cards 1 and 3 remain unaffected; no duplicate toolbar items appear; no other card gains focus
  - Verify: Inspect the toolbar item count — only one "Done" button should be visible; confirm cards 1 and 3 have no active first responder

### EC 6: Delete the Only Remaining Item

- [ ] **Scenario: Deleting the sole item in the list leaves an empty list without crashing**
  - Given: Wishlist 'wishlist-ec6-single' contains exactly one WishlistItemCard 'item-ec6-last' with a partially filled name
  - When: The user swipes left and taps "Delete" on 'item-ec6-last' via `.onDelete`
  - Then: The item is removed from `CreateWishlistViewModel`'s items array, the list renders with no cards (only the add-item row visible), and the app does not crash
  - Verify: Confirm the items array count drops to 0; confirm the add-item row remains interactive after deletion

### EC 7: Empty Name Field Binding

- [ ] **Scenario: Leaving the name field empty preserves an empty string in the model without crashing**
  - Given: WishlistItemCard 'item-ec7-emptyname' has an empty string bound to `WishlistItem.name` (user cleared the field)
  - When: The user taps outside the field or navigates to another card
  - Then: The empty string is preserved in the bound `WishlistItem` without any crash, nil coalescing error, or unexpected placeholder text injection
  - Verify: Inspect `WishlistItem.name` in the view model after the interaction — it must equal `""`, not nil; confirm the text field shows its placeholder text

### EC 8: Very Long itemLink URL

- [ ] **Scenario: An extremely long URL in itemLink does not break layout or crash**
  - Given: WishlistItemCard 'item-ec8-longurl' has a 2000-character URL string bound to `WishlistItem.itemLink`
  - When: The card renders in the list
  - Then: The `itemLink` text field displays without horizontal overflow, does not push sibling views out of bounds, and the card layout remains stable
  - Verify: Scroll through the list while 'item-ec8-longurl' is visible; confirm no layout constraints are broken and no crash occurs

### EC 9: Small Screen Layout (iPhone SE — 375pt width)

- [ ] **Scenario: Image frame respects minHeight: 180 on smallest supported iPhone screen**
  - Given: The app runs on an iPhone SE (3rd gen, 375pt wide) and wishlist 'wishlist-ec9-smallscreen' contains 3 WishlistItemCards
  - When: The user scrolls through the item list
  - Then: Each card's image area renders with at least `minHeight: 180`, no content is clipped outside its card boundary, and no layout overflow or scrolling glitch occurs
  - Verify: Run on a 375pt simulator; measure each card's image frame height is ≥ 180pt; confirm no horizontal overflow
