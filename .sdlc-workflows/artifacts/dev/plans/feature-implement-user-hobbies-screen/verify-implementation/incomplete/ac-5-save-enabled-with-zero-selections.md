# AC 5: Save Enabled with Zero Selections

- [x] **Scenario: Save button is always enabled regardless of selection count**
  - Given: `InterestsSelectionView` is open for user `user-ac5-empty` with no hobbies selected
  - When: the user inspects the "Save & Continue" / save button without tapping any chip
  - Then: the save button is active and tappable with zero hobbies selected
  - Verify: the button does not appear disabled or grayed out; tapping it initiates a Firestore write with an empty interests array
