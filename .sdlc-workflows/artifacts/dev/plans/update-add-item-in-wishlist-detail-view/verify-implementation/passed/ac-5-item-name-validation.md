# AC 5: Item Name Validation

- [x] **Scenario: Add button is disabled when item name is empty**
  - Given: `AddItemManualDetailSheet` is presented for item `'item-ac5-validation'` with `newItemName` bound to an empty string
  - When: The "Add" button's enabled/disabled logic is reviewed
  - Then: The `WishieButton` for the add action is disabled (e.g., `.disabled(viewModel.newItemName.trimmingCharacters(in: .whitespaces).isEmpty)`)
  - Verify: Code review confirms the disabled modifier is applied to the `WishieButton`, not a custom overlay, and correctly reflects `newItemName` being blank

- [x] **Scenario: Add button becomes enabled when a valid item name is entered**
  - Given: `AddItemManualDetailSheet` is presented for item `'item-ac5-valid'` with `newItemName` bound to a non-empty string
  - When: The button's disabled condition is evaluated
  - Then: The `WishieButton` is in an enabled state allowing the add action to proceed
  - Verify: Code review confirms the same disabled modifier evaluates to `false` when `newItemName` contains at least one non-whitespace character

