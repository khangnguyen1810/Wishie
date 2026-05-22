# EC 2: Sheet Dismissed and Reopened After Binding Refresh

- [x] **Scenario: Picker wheel reflects latest binding value on second open**
  - Given: `DateInputView` is in edit mode with `date` binding set to `dob-ec2-first` = March 8, 2000; the sheet has been opened once and dismissed without making changes
  - When: The `date` binding is externally updated to `dob-ec2-second` = July 22, 1998 (simulating a profile reload), and the sheet is opened again
  - Then: The date picker wheel opens positioned at July 22, 1998, not at the previously displayed March 8, 2000
  - Verify: Confirm `dateOfBirth` equals `dob-ec2-second` before opening; confirm wheel position after opening; confirm no residual state from the prior sheet session
