# EC 6: Tutorial Completion Persists Across App Restart

- [x] **Scenario: AppStorage persists hasSeenHomeTutorial after app is force-quit and relaunched**
  - Given: User 'user-ec6-persist' tapped "Done" on the final coach mark step, setting `AppStorage(WishieConstants.hasSeenHomeTutorial)` to `true`
  - When: The user force-quits the app and relaunches, navigating back to the Home screen
  - Then: `hasSeenHomeTutorial` remains `true` after relaunch; the tutorial overlay is not shown again
  - Verify: Confirm `AppStorage` write is not in-memory only; confirm the `UserDefaults` key for `WishieConstants.hasSeenHomeTutorial` holds `true` after process termination
