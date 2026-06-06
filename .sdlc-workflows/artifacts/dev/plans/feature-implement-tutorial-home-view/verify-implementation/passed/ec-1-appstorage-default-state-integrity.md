# EC 1: AppStorage Default State Integrity

- [x] **Scenario: Tutorial appears when AppStorage key is absent (fresh install)**
  - Given: User `user-ec1-fresh` has just installed the app and `hasSeenHomeTutorial` key does not exist in `UserDefaults`
  - When: The user authenticates and `HomeView` renders for the first time
  - Then: `AppStorage` resolves `hasSeenHomeTutorial` to its default value of `false`, and `HomeTutorialOverlayView` is displayed with a fade-in animation
  - Verify: Confirm `HomeTutorialOverlayView` is visible; confirm `UserDefaults` does not yet contain the `hasSeenHomeTutorial` key until the user dismisses the overlay
