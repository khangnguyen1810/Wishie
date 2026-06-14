# AC 1: Add-Item Entry Point — Bottom Sheet Presentation

- [x] **Scenario: Tapping "Add another gift" presents AddItemOptionSheet instead of appending an item directly**
  - Given: `CreateWishlistPage2` is rendered and `CreateWishlistViewModel` holds zero or more items (test data namespace: `ac1-entry`)
  - When: The user taps the "Add another gift" button
  - Then: A bottom sheet view identified as `AddItemOptionSheet` is presented, exposing two distinct action options ("Paste a product link" and "Fill in manually"), and no new `WishlistItem` is appended to `viewModel.items` at this point
  - Verify:
    - `CreateWishlistPage2` has a state variable (e.g., `showAddItemSheet`) toggled to `true` by the button's action
    - `AddItemOptionSheet` is bound via `.sheet` or `.confirmationDialog` to that state variable
    - `CreateWishlistViewModel.items.count` remains unchanged until an option is chosen

---

