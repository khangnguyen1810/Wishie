# AC 3: Step 1 — Add Button Spotlight and Tooltip

- [x] **Scenario: Step 1 spotlights the add button with correct content**
  - Given: The coach marks tutorial is active at step index 0 for user `user-ac3-step1`
  - When: The overlay renders step 1
  - Then: The add (+) button is spotlighted via an even-odd fill cutout in the dim overlay; the tooltip displays the title "Create or Join" with its explanation message; a "Next" button is visible and tappable
  - Verify: The dim overlay covers the entire screen except the add button region; tooltip title and message match the `CoachMarkStep` data for step 1; no "Done" button is shown
