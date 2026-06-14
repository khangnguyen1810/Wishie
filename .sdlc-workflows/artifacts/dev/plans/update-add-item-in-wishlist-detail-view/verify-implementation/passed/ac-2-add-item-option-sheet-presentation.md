# AC 2: Add Item Option Sheet Presentation

- [x] **Scenario: Tapping the FAB presents AddItemOptionSheet**
  - Given: The "Add item" FAB is visible for wishlist `'wishlist-ac2-sheet'` (user is owner)
  - When: The FAB's action handler is reviewed
  - Then: The action sets a `showAddItemOptionSheet` (or equivalent) state flag to `true`, which is bound to `AddItemOptionSheet` via a `.sheet` modifier
  - Verify: Code review confirms FAB action exclusively toggles the option sheet flag; `AddItemOptionSheet` is not constructed inline in the FAB body
