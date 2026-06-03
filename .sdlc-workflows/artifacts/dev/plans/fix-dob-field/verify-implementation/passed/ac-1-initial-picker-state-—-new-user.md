# AC 1: Initial Picker State — New User

- [x] **Scenario: Picker opens at today's date when no prior DOB exists**
  - Given: `DateInputView` is instantiated inside `SignUpView` with the `dob` binding holding `Date()` (today)
  - When: The user taps the date input field to open the date picker sheet
  - Then: The `DatePicker` wheel displays today's date as the initially selected value
  - Verify: Confirm the picker's selected date matches the value passed via the `date` binding at the moment the sheet appears

