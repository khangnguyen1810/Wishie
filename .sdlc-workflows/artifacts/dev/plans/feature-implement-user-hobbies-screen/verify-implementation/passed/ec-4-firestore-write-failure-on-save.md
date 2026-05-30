# EC 4: Firestore Write Failure on Save

- [x] **Scenario: Firestore Error on Save Surfaces Alert Without Crashing**
  - Given: User `"user-ec4-write-fail"` is on `InterestsSelectionView` with one or more chips selected, and Firestore is configured to reject the write (e.g., network offline or permission denied)
  - When: The user taps "Save & Continue"
  - Then: The view displays an error alert describing the failure; `InterestsSelectionView` remains visible; the coordinator does NOT transition to `AppState.authenticated`; the app does not crash
  - Verify: An error alert is presented; coordinator state remains `AppState.interestsSetup`; `hasCompletedInterestsSetup` is NOT set to `true` in Firestore

