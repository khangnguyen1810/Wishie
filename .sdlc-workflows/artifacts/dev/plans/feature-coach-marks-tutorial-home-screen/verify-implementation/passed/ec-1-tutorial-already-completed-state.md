# EC 1: Tutorial Already Completed State

- [x] **Scenario: Tutorial overlay does not appear on subsequent launches after completion**
  - Given: User 'user-ec1-returning' has `AppStorage(WishieConstants.hasSeenHomeTutorial)` set to `true` from a previous session
  - When: The user navigates to the Home screen
  - Then: `HomeTutorialOverlayView` is NOT presented; no coach mark overlay renders; the Home screen is fully interactive without any dimming or tooltip
  - Verify: Confirm `showTutorial` state remains `false`; confirm no `CoachMarkOverlayView` is injected into the view hierarchy

