# AC 3: Tap-to-Dismiss Tutorial

- [x] **Scenario: Tapping anywhere on the tutorial overlay dismisses it**
  - Given: User "user-ac3-tap-dismiss" is authenticated and viewing `HomeView` with `HomeTutorialOverlayView` visible (`hasSeenHomeTutorial = false`)
  - When: The user taps anywhere on the tutorial overlay
  - Then: The tutorial overlay is dismissed and is no longer visible on screen
  - Verify: `HomeTutorialOverlayView` is removed from the view hierarchy after the tap gesture is detected; `HomeView` content is fully interactive
