# EC 4: New User Flow — Default Date Initialization Does Not Regress

- [x] **Scenario: SignUpView picker opens at the binding's initial Date() value**
  - Given: `DateInputView` is rendered in `SignUpView` with `date` binding set to `dob-ec4-new` = `Date()` (today) and `isCreating = true`, representing a brand-new user who has not changed the DOB field
  - When: The user taps the date input field to open the picker sheet
  - Then: The date picker wheel opens at today's date (`dob-ec4-new`), matching the bound value, with no crash or unexpected date displacement
  - Verify: Confirm the wheel's initial position equals today's date; confirm the custom `init` initializes `dateOfBirth` from the binding rather than hardcoding `Date()` independently
