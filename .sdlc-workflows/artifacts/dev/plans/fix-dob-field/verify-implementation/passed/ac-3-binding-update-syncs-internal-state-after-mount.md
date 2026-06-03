# AC 3: Binding Update Syncs Internal State After Mount

- [x] **Scenario: Internal state updates when the external binding changes post-mount**
  - Given: `DateInputView` is already rendered with the `date` binding initially at `Date()` (today)
  - When: The external binding updates to `1990-03-22` (e.g., via `viewModel.populate`)
  - Then: The internal `dateOfBirth` `@State` variable updates to March 22, 1990 so the picker reflects the new value on next open
  - Verify: Open the picker sheet after the binding change and confirm the wheel lands on `1990-03-22`

