# AC 4: Hobby Chip Selection and Deselection

- [x] **Scenario: User selects and deselects hobby chips across multiple categories**
  - Given: `InterestsSelectionView` is open for user `user-ac4-select` with no pre-selected interests
  - When: the user taps a chip to select it, then taps the same chip again to deselect it, and also taps chips in two different categories
  - Then: selected chips display at `scaleEffect(1.05)` with the selected visual style; deselected chips return to `scaleEffect(1.0)`; multiple simultaneous selections across categories are permitted
  - Verify: the selection toggle uses `.spring(response: 0.3, dampingFraction: 0.6)` animation; selected and unselected chips have visually distinct appearances using Wishie accent colors
