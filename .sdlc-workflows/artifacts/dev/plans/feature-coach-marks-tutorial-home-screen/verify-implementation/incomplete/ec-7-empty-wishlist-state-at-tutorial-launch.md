# EC 7: Empty Wishlist State at Tutorial Launch

- [x] **Scenario: Tutorial completes fully even when the user has zero wishlist items**
  - Given: User 'user-ec7-empty' is launching the Home screen for the first time with an empty wishlist (no wishlist cards rendered, no swipeable items present)
  - When: The coach marks tutorial progresses through all three steps including the swipe gesture hint (step 3)
  - Then: Step 3 renders its centered tooltip without requiring any wishlist card anchor; all three steps complete and "Done" dismisses the tutorial correctly
  - Verify: Confirm no anchor resolution is attempted for a wishlist card in any step; confirm `hasSeenHomeTutorial` is set to `true` after tapping "Done" in this state
