# Verification Context — Acceptance Scenarios

## Purpose

Define testable acceptance scenarios in Given/When/Then format to verify the implementation meets functional requirements and success criteria.
This document serves as the single source of truth for acceptance verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "user-ac1-login", "product-ac2-checkout"). No two scenarios should share mutable state.

## Acceptance Scenarios:

### AC 1: Fixed Image Frame Rendering

- [ ] **Scenario: WishlistItemCard renders selected image at fixed frame with consistent cropping**
  - Given: A `WishlistItem` named "item-ac1-image" has an image selected and is rendered inside `WishlistItemCard`
  - When: The card appears on screen
  - Then: The image container fills the full available width (`maxWidth: .infinity`) with a minimum height of 180 pt, the image content scales to fill using `.scaledToFill()`, and is clipped to a continuous `RoundedRectangle(cornerRadius: 12)` with no overflow outside the frame
  - Verify: Inspect the view hierarchy to confirm `frame(maxWidth: .infinity, minHeight: 180)`, `.scaledToFill()`, and `clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))` are applied to the image; confirm that images of different aspect ratios (portrait, landscape, square) all crop uniformly within the same visible area

### AC 2: Upload Placeholder Display

- [ ] **Scenario: WishlistItemCard shows centered upload placeholder when no image is selected**
  - Given: A `WishlistItem` named "item-ac2-placeholder" has no image selected and is rendered inside `WishlistItemCard`
  - When: The card appears on screen
  - Then: The image area displays a centered `Image("upload")` icon and an "Add photo" label; no real image content is shown
  - Verify: Confirm the placeholder container occupies the same fixed frame (`maxWidth: .infinity`, `minHeight: 180`) as the image state; confirm both the upload icon and "Add photo" label are vertically and horizontally centered within that area

### AC 3: Keyboard Toolbar Dismisses All Three Focus States

- [ ] **Scenario: Done button in keyboard toolbar dismisses keyboard from the name field**
  - Given: `CreateWishlistPage2` is shown with at least one `WishlistItemCard` for item "item-ac3-name" and the name text field is focused
  - When: The user taps the "Done" button in the keyboard toolbar
  - Then: `focusedField` is set to `nil` and the keyboard dismisses
  - Verify: After tapping Done, the on-screen keyboard is no longer visible and no text field retains focus

- [ ] **Scenario: Done button in keyboard toolbar dismisses keyboard from the description field**
  - Given: `CreateWishlistPage2` is shown with at least one `WishlistItemCard` for item "item-ac3-desc" and the description text field is focused
  - When: The user taps the "Done" button in the keyboard toolbar
  - Then: `focusedField` is set to `nil` and the keyboard dismisses
  - Verify: After tapping Done, the on-screen keyboard is no longer visible and no text field retains focus

- [ ] **Scenario: Done button in keyboard toolbar dismisses keyboard from the itemLink field**
  - Given: `CreateWishlistPage2` is shown with at least one `WishlistItemCard` for item "item-ac3-link" and the itemLink text field is focused
  - When: The user taps the "Done" button in the keyboard toolbar
  - Then: `focusedField` is set to `nil` and the keyboard dismisses
  - Verify: After tapping Done, the on-screen keyboard is no longer visible and no text field retains focus

### AC 4: Three Input Fields Without Price

- [ ] **Scenario: WishlistItemCard exposes exactly name, description, and itemLink fields**
  - Given: `CreateWishlistPage2` is shown with a `WishlistItem` named "item-ac4-fields"
  - When: The user inspects the visible input fields inside `WishlistItemCard`
  - Then: Exactly three text input fields are present (name, description, itemLink), each bound to the corresponding property of `WishlistItem`; no price field is rendered anywhere on the card
  - Verify: Interact with each field and confirm values flow into `WishlistItem.name`, `WishlistItem.description`, and `WishlistItem.itemLink` respectively; confirm the `WishlistItem` model's price property (if it exists) is never displayed or mutated by this screen

### AC 5: Add and Delete Wishlist Items

- [ ] **Scenario: User can append a new empty item via the styled add-item row**
  - Given: `CreateWishlistPage2` is shown with one existing `WishlistItem` "item-ac5-existing" in the list
  - When: The user taps the styled add-item row at the bottom of the list
  - Then: A new `WishlistItem()` is appended to the list and a new `WishlistItemCard` becomes visible
  - Verify: The list count increases by one; the newly appended card has empty name, description, and itemLink fields and shows the upload placeholder

- [ ] **Scenario: User can delete an existing item via swipe-to-delete**
  - Given: `CreateWishlistPage2` is shown with two `WishlistItem` entries "item-ac5-delete-a" and "item-ac5-delete-b"
  - When: The user swipe-deletes "item-ac5-delete-a"
  - Then: The item is removed from the list and only "item-ac5-delete-b" remains
  - Verify: The list count decreases by one; the deleted card is no longer visible; the remaining card retains its data unchanged

### AC 6: Styled Add-Item Row Uses Project Design Tokens

- [ ] **Scenario: Add-item row renders with project color tokens and WishieFont typography**
  - Given: `CreateWishlistPage2` is shown and the add-item row is visible
  - When: The user views the bottom of the item list
  - Then: The add-item row is visually styled using project color tokens (`.wishiePink`, `.lightYellow1`, or `.white` as defined in the design) and uses `WishieFont` typographic styles; it is not a plain `Text("+ add new item")`
  - Verify: Inspect the add-item row's foreground/background colors against the project color token definitions in `Assets.xcassets`; confirm font styling matches a `WishieFont` style rather than a system default font
