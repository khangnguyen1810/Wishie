# EC 3: isCreating Flag Boundary — Edit Mode Does Not Reset to Today

- [x] **Scenario: Displayed day/month/year fields use synchronized dateOfBirth in edit mode**
  - Given: `DateInputView` is rendered with `isCreating = false` and `date` binding set to `dob-ec3-edit` = November 3, 1990, and `dateOfBirth` has been synchronized to November 3, 1990
  - When: The view re-renders (e.g., parent state change triggers body re-evaluation) without any change to the `date` binding
  - Then: The displayed day, month, and year fields continue to reflect November 3, 1990, and `dateOfBirth` is not reset to `Date()`
  - Verify: Confirm the fields show day=3, month=November, year=1990 after re-render; confirm `dateOfBirth` remains unchanged at `dob-ec3-edit`

