# AC 1: First Launch Tutorial Trigger

- [x] **Scenario: Tutorial appears on first Home screen visit**
  - Given: `hasSeenHomeTutorial` is `false` (not yet set in AppStorage) for user `user-ac1-first-launch`
  - When: The user navigates to the Home screen for the first time
  - Then: The `CoachMarkOverlayView` appears over the Home screen with the tutorial at step 1
  - Verify: The overlay is visible; the current step index is 0; the add (+) button spotlight cutout is rendered through the dim overlay
