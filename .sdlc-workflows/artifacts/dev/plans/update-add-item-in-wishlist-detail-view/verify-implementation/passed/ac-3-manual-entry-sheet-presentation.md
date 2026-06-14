# AC 3: Manual Entry Sheet Presentation

- [x] **Scenario: Selecting "Fill in manually" dismisses option sheet then presents AddItemManualDetailSheet**
  - Given: `AddItemOptionSheet` is displayed for wishlist `'wishlist-ac3-manual'`
  - When: The "Fill in manually" callback in the option sheet is triggered
  - Then: The option sheet is dismissed first (via `showAddItemOptionSheet = false`), then `AddItemManualDetailSheet` is presented after a `DispatchQueue.main.asyncAfter` delay consistent with the existing `showDeleteConfirmation` pattern
  - Verify: Code review confirms the sequential dismiss-then-present pattern using `asyncAfter`; `AddItemManualDetailSheet` contains fields for item name (required), description, image (`ImagePickerBox`), and product link (optional)

