# EC 9: Rapid Chip Tap Toggle Stability

- [x] **Scenario: Rapidly Tapping the Same Chip Multiple Times Results in Correct Final Toggle State**
  - Given: User `"user-ec9-rapid-tap"` is on `InterestsSelectionView` with the "Gaming" chip in an unselected state
  - When: The user taps the "Gaming" chip five times in rapid succession
  - Then: The chip's selection state accurately reflects an odd number of taps (selected after 1, 3, 5 taps) or even number (unselected after 2, 4 taps); no duplicate entries are added to the selection array; the spring animation completes without visual artefacts
  - Verify: The `selectedInterests` set contains "Gaming" once (not duplicated) after an odd tap count; the chip renders at `scaleEffect(1.05)` in selected state and `scaleEffect(1.0)` in unselected state
