# AC 7: Save Persists Interests to Firestore and Transitions to HomeView (Onboarding)

- [x] **Scenario: Saving selected interests in onboarding context persists data and navigates to HomeView**
  - Given: `InterestsSelectionView` is open with `isOnboarding: true` for user `user-ac7-onboard` who has selected three hobbies across two categories
  - When: the user taps "Save & Continue"
  - Then: the selected interests array is written to Firestore under `users/user-ac7-onboard`; `hasCompletedInterestsSetup` is set to `true` in Firestore; the coordinator transitions to `AppState.authenticated`; HomeView is displayed
  - Verify: Firestore document for `user-ac7-onboard` contains the correct `interests` array and `hasCompletedInterestsSetup: true`; HomeView is rendered after the action completes
