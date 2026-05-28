# AC 8: No Back Button or Swipe Dismiss in Onboarding Context

- [x] **Scenario: Onboarding Interests screen cannot be dismissed without tapping Save & Continue**
  - Given: `InterestsSelectionView` is displayed with `isOnboarding: true` for user `user-ac8-nodismiss`
  - When: the user attempts to swipe the view down to dismiss it, or looks for a back navigation button
  - Then: no back button is visible in the TopAppBar left slot; swipe-to-dismiss gesture is disabled; the only available exit is the "Save & Continue" button
  - Verify: the view remains on screen after a swipe gesture; no navigation controls other than "Save & Continue" are tappable
