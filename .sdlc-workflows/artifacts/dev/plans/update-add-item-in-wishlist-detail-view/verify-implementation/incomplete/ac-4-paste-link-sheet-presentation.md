# AC 4: Paste Link Sheet Presentation

- [x] **Scenario: Selecting "Paste a product link" dismisses option sheet then presents AddItemPasteLinkDetailSheet**
  - Given: `AddItemOptionSheet` is displayed for wishlist `'wishlist-ac4-paste'`
  - When: The "Paste a product link" callback is triggered
  - Then: The option sheet is dismissed and `AddItemPasteLinkDetailSheet` is presented after the same `asyncAfter` delay, containing a URL input field, a fetch action via `ProductMetadataService`, a metadata preview section, and an "Add to wishlist" confirm button
  - Verify: Code review confirms the dismiss-before-present pattern and that `AddItemPasteLinkDetailSheet` exposes all required UI elements bound to `viewModel` state
