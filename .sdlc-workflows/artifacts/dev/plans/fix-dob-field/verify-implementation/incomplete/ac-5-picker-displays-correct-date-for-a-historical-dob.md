# AC 5: Picker Displays Correct Date for a Historical DOB

- [x] **Scenario: Picker scrolls to historical date when bound DOB is far in the past**
  - Given: The `date` binding carries `1988-11-30` and `viewModel.populate` has completed
  - When: The user opens the date picker sheet from `EditProfileView`
  - Then: The `DatePicker` wheel is positioned at November 30, 1988 as the active selection
  - Verify: Visually confirm month, day, and year wheels all match the bound DOB value
