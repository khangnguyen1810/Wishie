# AC 5: Tutorial Does Not Reappear on Subsequent Launches

- [x] **Scenario: Tutorial overlay is not shown after it has been dismissed once**
  - Given: User "user-ac5-no-repeat" has previously dismissed the tutorial (`hasSeenHomeTutorial = true` in `AppStorage`)
  - When: The user relaunches the app and `HomeView` is presented
  - Then: `HomeTutorialOverlayView` is not displayed
  - Verify: The overlay view is absent from the view hierarchy on every subsequent app launch; `HomeView` renders normally without any tutorial layer
