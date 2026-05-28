# AC 3: Keyboard Toolbar Dismisses All Three Focus States

- [x] **Scenario: Done button in keyboard toolbar dismisses keyboard from the name field**
  - Given: `CreateWishlistPage2` is shown with at least one `WishlistItemCard` for item "item-ac3-name" and the name text field is focused
  - When: The user taps the "Done" button in the keyboard toolbar
  - Then: `focusedField` is set to `nil` and the keyboard dismisses
  - Verify: After tapping Done, the on-screen keyboard is no longer visible and no text field retains focus

- [x] **Scenario: Done button in keyboard toolbar dismisses keyboard from the description field**
  - Given: `CreateWishlistPage2` is shown with at least one `WishlistItemCard` for item "item-ac3-desc" and the description text field is focused
  - When: The user taps the "Done" button in the keyboard toolbar
  - Then: `focusedField` is set to `nil` and the keyboard dismisses
  - Verify: After tapping Done, the on-screen keyboard is no longer visible and no text field retains focus

- [x] **Scenario: Done button in keyboard toolbar dismisses keyboard from the itemLink field**
  - Given: `CreateWishlistPage2` is shown with at least one `WishlistItemCard` for item "item-ac3-link" and the itemLink text field is focused
  - When: The user taps the "Done" button in the keyboard toolbar
  - Then: `focusedField` is set to `nil` and the keyboard dismisses
  - Verify: After tapping Done, the on-screen keyboard is no longer visible and no text field retains focus

