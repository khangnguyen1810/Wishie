# AC 2: Initial Picker State — Existing User With Saved DOB

- [x] **Scenario: Picker opens at saved DOB after async population completes**
  - Given: `DateInputView` is used inside `EditProfileView`; `viewModel.populate(from: userModel)` sets `viewModel.dateOfBirth` to `1995-06-15` in `onAppear`
  - When: Async population finishes and the user taps the date input field to open the sheet
  - Then: The `DatePicker` wheel shows June 15, 1995 as the selected date — not today
  - Verify: Confirm internal `dateOfBirth` state reflects the bound value before the sheet is presented
