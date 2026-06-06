# Verification Context — Acceptance Scenarios

## Purpose

Define testable acceptance scenarios in Given/When/Then format to verify the implementation meets functional requirements and success criteria.
This document serves as the single source of truth for acceptance verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "user-ac1-login", "product-ac2-checkout"). No two scenarios should share mutable state.

## Acceptance Scenarios:

### AC 1: First Launch Tutorial Trigger

- [ ] **Scenario: Tutorial appears on first Home screen visit**
  - Given: `hasSeenHomeTutorial` is `false` (not yet set in AppStorage) for user `user-ac1-first-launch`
  - When: The user navigates to the Home screen for the first time
  - Then: The `CoachMarkOverlayView` appears over the Home screen with the tutorial at step 1
  - Verify: The overlay is visible; the current step index is 0; the add (+) button spotlight cutout is rendered through the dim overlay

### AC 2: Tutorial Suppressed After Completion

- [ ] **Scenario: Tutorial does not appear for a returning user**
  - Given: `hasSeenHomeTutorial` is `true` in AppStorage for user `user-ac2-returning`
  - When: The user navigates to the Home screen
  - Then: No coach marks overlay is displayed and the Home screen is fully interactive
  - Verify: `CoachMarkOverlayView` is not present in the view hierarchy; all Home screen controls are accessible without obstruction

### AC 3: Step 1 — Add Button Spotlight and Tooltip

- [ ] **Scenario: Step 1 spotlights the add button with correct content**
  - Given: The coach marks tutorial is active at step index 0 for user `user-ac3-step1`
  - When: The overlay renders step 1
  - Then: The add (+) button is spotlighted via an even-odd fill cutout in the dim overlay; the tooltip displays the title "Create or Join" with its explanation message; a "Next" button is visible and tappable
  - Verify: The dim overlay covers the entire screen except the add button region; tooltip title and message match the `CoachMarkStep` data for step 1; no "Done" button is shown

### AC 4: Step 2 — Tab Selector Spotlight and Tooltip

- [ ] **Scenario: Tapping Next from Step 1 advances to Step 2 with tab selector spotlight**
  - Given: The coach marks tutorial is active at step index 0 for user `user-ac4-step2`
  - When: The user taps the "Next" button
  - Then: The overlay transitions to step 2; the tab selector `HStack` is spotlighted; the tooltip displays the title "Your Lists" with its explanation message; a "Next" button is visible
  - Verify: Step index advances to 1; the spotlight cutout aligns with the tab selector bounds resolved from `CoachMarkBoundsKey`; "Done" button is not present

### AC 5: Step 3 — Swipe Gesture Hint Without Spotlight

- [ ] **Scenario: Tapping Next from Step 2 advances to Step 3 with no spotlight**
  - Given: The coach marks tutorial is active at step index 1 for user `user-ac5-step3`
  - When: The user taps the "Next" button
  - Then: The overlay transitions to step 3; no spotlight cutout is rendered; a centered tooltip displays the title "Swipe to Manage" with the swipe-left explanation message; a "Done" button is visible instead of "Next"
  - Verify: Step index is 2; `anchorID` for step 3 is `nil` resulting in no spotlight path drawn; "Next" button is absent

### AC 6: Tutorial Completion Persists via AppStorage

- [ ] **Scenario: Tapping Done on the final step dismisses tutorial and persists state**
  - Given: The coach marks tutorial is active at step index 2 (final step) for user `user-ac6-completion`
  - When: The user taps the "Done" button
  - Then: The overlay dismisses with a fade-out animation; `hasSeenHomeTutorial` is written as `true` to AppStorage; navigating away and back to the Home screen does not show the tutorial again
  - Verify: The overlay is removed from the view hierarchy after dismissal; the AppStorage key `WishieConstants.hasSeenHomeTutorial` equals `true`

### AC 7: Dim Overlay Applied on Spotlight Steps

- [ ] **Scenario: Non-spotlighted UI is visually dimmed when a spotlight step is active**
  - Given: The coach marks tutorial is active at step 1 or step 2 for user `user-ac7-dim`
  - When: The spotlight step renders
  - Then: A dim layer covers the entire screen; only the spotlighted element is visually clear through the even-odd fill cutout
  - Verify: The `Path` with `FillStyle(eoFill: true)` produces a visible hole at the spotlighted element's `CGRect`; all surrounding UI is obscured by the overlay

### AC 8: Step Transition Animation

- [ ] **Scenario: Advancing between steps animates with easeInOut**
  - Given: The coach marks tutorial is active at step 1 for user `user-ac8-animation`
  - When: The user taps the "Next" button to advance to step 2
  - Then: The tooltip and spotlight transition smoothly using `.easeInOut(duration: 0.3)`; no abrupt jump or flash occurs between steps
  - Verify: The `withAnimation(.easeInOut(duration: 0.3))` block wraps the step index increment; the spotlight and tooltip update in sync within the same animation transaction
