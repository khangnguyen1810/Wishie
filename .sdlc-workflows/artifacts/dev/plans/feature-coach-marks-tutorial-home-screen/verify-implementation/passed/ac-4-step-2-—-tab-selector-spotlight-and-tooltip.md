# AC 4: Step 2 — Tab Selector Spotlight and Tooltip

- [x] **Scenario: Tapping Next from Step 1 advances to Step 2 with tab selector spotlight**
  - Given: The coach marks tutorial is active at step index 0 for user `user-ac4-step2`
  - When: The user taps the "Next" button
  - Then: The overlay transitions to step 2; the tab selector `HStack` is spotlighted; the tooltip displays the title "Your Lists" with its explanation message; a "Next" button is visible
  - Verify: Step index advances to 1; the spotlight cutout aligns with the tab selector bounds resolved from `CoachMarkBoundsKey`; "Done" button is not present

