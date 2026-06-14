# EC 1: Item Name Validation — Empty Input

- [x] **Scenario: Add button is disabled when item name is empty**
  - Given: `AddItemManualDetailSheet` is presented with `newItemName` bound to an empty string `""`
  - When: The user has not entered any text in the item name field
  - Then: The primary "Add" `WishieButton` remains disabled and cannot be tapped
  - Verify: Confirm the button's `disabled` modifier or `isEnabled` condition evaluates `newItemName.isEmpty` and blocks the action

- [x] **Scenario: Add button remains disabled for whitespace-only item name**
  - Given: `AddItemManualDetailSheet` is presented with `newItemName` bound to `"   "` (whitespace only)
  - When: The user has entered only whitespace characters in the item name field
  - Then: The primary "Add" `WishieButton` remains disabled
  - Verify: Confirm the validation trims whitespace (e.g., `newItemName.trimmingCharacters(in: .whitespaces).isEmpty`) before enabling the button

---

