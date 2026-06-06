# AC 5: Step 3 — Swipe Gesture Hint Without Spotlight

- [x] **Scenario: Tapping Next from Step 2 advances to Step 3 with no spotlight**
  - Given: The coach marks tutorial is active at step index 1 for user `user-ac5-step3`
  - When: The user taps the "Next" button
  - Then: The overlay transitions to step 3; no spotlight cutout is rendered; a centered tooltip displays the title "Swipe to Manage" with the swipe-left explanation message; a "Done" button is visible instead of "Next"
  - Verify: Step index is 2; `anchorID` for step 3 is `nil` resulting in no spotlight path drawn; "Next" button is absent
