# AC 4: Tutorial Persistence After Dismissal

- [x] **Scenario: `hasSeenHomeTutorial` is persisted as `true` upon dismissal**
  - Given: User "user-ac4-persistence" taps to dismiss the tutorial on `HomeView`
  - When: The dismissal action is triggered
  - Then: `AppStorage` key `hasSeenHomeTutorial` is set to `true` and stored on device
  - Verify: Reading `AppStorage["hasSeenHomeTutorial"]` returns `true` immediately after dismissal; the value survives an app restart
