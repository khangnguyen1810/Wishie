# AC 2: Tutorial Suppressed After Completion

- [x] **Scenario: Tutorial does not appear for a returning user**
  - Given: `hasSeenHomeTutorial` is `true` in AppStorage for user `user-ac2-returning`
  - When: The user navigates to the Home screen
  - Then: No coach marks overlay is displayed and the Home screen is fully interactive
  - Verify: `CoachMarkOverlayView` is not present in the view hierarchy; all Home screen controls are accessible without obstruction
