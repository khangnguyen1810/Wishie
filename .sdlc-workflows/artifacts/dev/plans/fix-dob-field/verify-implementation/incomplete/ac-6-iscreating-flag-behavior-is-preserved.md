# AC 6: isCreating Flag Behavior Is Preserved

- [x] **Scenario: Day/month/year display fields follow isCreating logic unchanged**
  - Given: `DateInputView` is in creation mode (`isCreating` is `true`) and the bound `date` is `2000-01-01`
  - When: The user views and interacts with the date input fields
  - Then: The displayed day, month, and year values follow the existing `isCreating` conditional logic — unaffected by the initialization fix
  - Verify: Confirm the rendered display fields match the pre-fix behavior under the `isCreating` branch
