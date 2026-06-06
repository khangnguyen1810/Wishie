# AC 6: Tutorial Completion Persists via AppStorage

- [x] **Scenario: Tapping Done on the final step dismisses tutorial and persists state**
  - Given: The coach marks tutorial is active at step index 2 (final step) for user `user-ac6-completion`
  - When: The user taps the "Done" button
  - Then: The overlay dismisses with a fade-out animation; `hasSeenHomeTutorial` is written as `true` to AppStorage; navigating away and back to the Home screen does not show the tutorial again
  - Verify: The overlay is removed from the view hierarchy after dismissal; the AppStorage key `WishieConstants.hasSeenHomeTutorial` equals `true`

