# EC 2: Persistence Survives App Restart

- [x] **Scenario: Tutorial does not reappear after dismissal and cold app relaunch**
  - Given: User `user-ec2-dismissed` has previously dismissed the tutorial (i.e., `hasSeenHomeTutorial` is `true` in `UserDefaults`)
  - When: The user force-quits and relaunches the app, then authenticates and navigates to `HomeView`
  - Then: `HomeTutorialOverlayView` is never rendered; `HomeView` loads directly without any overlay present
  - Verify: Confirm `UserDefaults` value for `hasSeenHomeTutorial` key (from `WishieConstants`) is `true`; confirm no overlay layer appears in the view hierarchy

