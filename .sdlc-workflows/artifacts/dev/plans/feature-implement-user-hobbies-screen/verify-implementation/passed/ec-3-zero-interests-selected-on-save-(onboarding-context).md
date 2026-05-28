# EC 3: Zero Interests Selected on Save (Onboarding Context)

- [x] **Scenario: Save with Empty Selection Persists Flag and Advances to HomeView**
  - Given: User `"user-ec3-empty-save"` is on `InterestsSelectionView` in onboarding mode (`isOnboarding: true`) with zero hobby chips selected
  - When: The user taps "Save & Continue"
  - Then: A Firestore write persists an empty `interests` array and sets `hasCompletedInterestsSetup = true`; the coordinator transitions to `AppState.authenticated`; `HomeView` is displayed
  - Verify: The Firestore document for `"user-ec3-empty-save"` has `interests: []` and `hasCompletedInterestsSetup: true`; no error alert is shown; `InterestsSelectionView` is dismissed

