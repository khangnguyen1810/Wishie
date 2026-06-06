# Verification Context — Edge Case Scenarios

## Purpose

Define testable edge case scenarios in Given/When/Then format to verify the implementation handles boundary conditions, error states, and non-functional requirements.
This document serves as the single source of truth for edge case verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "cart-ec1-empty", "user-ec2-locked"). No two scenarios should share mutable state.

## Edge Case Scenarios:

### EC 1: Tutorial Already Completed State

- [ ] **Scenario: Tutorial overlay does not appear on subsequent launches after completion**
  - Given: User 'user-ec1-returning' has `AppStorage(WishieConstants.hasSeenHomeTutorial)` set to `true` from a previous session
  - When: The user navigates to the Home screen
  - Then: `HomeTutorialOverlayView` is NOT presented; no coach mark overlay renders; the Home screen is fully interactive without any dimming or tooltip
  - Verify: Confirm `showTutorial` state remains `false`; confirm no `CoachMarkOverlayView` is injected into the view hierarchy

### EC 2: Nil Anchor — Step With No Spotlight Element

- [ ] **Scenario: Step 3 renders centered tooltip without a spotlight cutout**
  - Given: User 'user-ec2-step3' has the tutorial active and `currentStep` is at index 2 (swipe gesture hint, `anchorID: nil`)
  - When: The coach mark overlay renders step 3
  - Then: No spotlight hole is punched through the dim overlay; the dim layer covers the entire screen uniformly; the tooltip is centered on screen without crashing
  - Verify: Confirm `CoachMarkOverlayView` does not attempt to resolve `Anchor<CGRect>` when `anchorID` is nil; confirm no runtime crash or out-of-bounds access occurs

### EC 3: Anchor Not Yet Resolved at Render Time

- [ ] **Scenario: Overlay renders safely when PreferenceKey anchor has not propagated yet**
  - Given: User 'user-ec3-timing' has the tutorial triggered immediately on first launch before the view layout pass completes and `CoachMarkBoundsKey` has not yet emitted a value for the add-button anchor
  - When: `HomeTutorialOverlayView` attempts to read the anchor for step 1 from the `GeometryProxy`
  - Then: The overlay renders in a safe fallback state (e.g., no spotlight or full-screen dim) without crashing; the spotlight does not appear in an incorrect screen position
  - Verify: Confirm the `bounds[anchorID]` optional lookup returns nil gracefully; confirm the app does not crash with a force-unwrap or index error

### EC 4: Rapid Successive "Next" Button Taps

- [ ] **Scenario: Multiple rapid taps on "Next" do not skip steps or corrupt step index**
  - Given: User 'user-ec4-rapid' is on step 1 of the coach marks tutorial with the "Next" button visible
  - When: The user taps "Next" three times in rapid succession before the `.easeInOut(duration: 0.3)` transition completes
  - Then: The tutorial advances by exactly one step per intentional tap; the `currentStep` index does not exceed the bounds of the `CoachMarkStep` array; no index-out-of-range crash occurs
  - Verify: Confirm step index is clamped or guarded; confirm the final displayed step does not exceed index 2

### EC 5: Safe Area and Overlay Alignment on Devices with Notch/Dynamic Island

- [ ] **Scenario: Spotlight cutout aligns correctly with the add button on a device with Dynamic Island**
  - Given: User 'user-ec5-notch' is on an iPhone 15 Pro (Dynamic Island) launching the tutorial for the first time
  - When: Step 1 renders and spotlights the add (+) button in the top navigation bar
  - Then: The spotlight cutout precisely frames the add button without being offset by the safe area inset; no part of the dim overlay bleeds into the cutout area
  - Verify: Confirm `HomeTutorialOverlayView` uses `.ignoresSafeArea()` on the overlay container; confirm the `Anchor<CGRect>` resolved rect matches the visual button position on-screen

### EC 6: Tutorial Completion Persists Across App Restart

- [ ] **Scenario: AppStorage persists hasSeenHomeTutorial after app is force-quit and relaunched**
  - Given: User 'user-ec6-persist' tapped "Done" on the final coach mark step, setting `AppStorage(WishieConstants.hasSeenHomeTutorial)` to `true`
  - When: The user force-quits the app and relaunches, navigating back to the Home screen
  - Then: `hasSeenHomeTutorial` remains `true` after relaunch; the tutorial overlay is not shown again
  - Verify: Confirm `AppStorage` write is not in-memory only; confirm the `UserDefaults` key for `WishieConstants.hasSeenHomeTutorial` holds `true` after process termination

### EC 7: Empty Wishlist State at Tutorial Launch

- [ ] **Scenario: Tutorial completes fully even when the user has zero wishlist items**
  - Given: User 'user-ec7-empty' is launching the Home screen for the first time with an empty wishlist (no wishlist cards rendered, no swipeable items present)
  - When: The coach marks tutorial progresses through all three steps including the swipe gesture hint (step 3)
  - Then: Step 3 renders its centered tooltip without requiring any wishlist card anchor; all three steps complete and "Done" dismisses the tutorial correctly
  - Verify: Confirm no anchor resolution is attempted for a wishlist card in any step; confirm `hasSeenHomeTutorial` is set to `true` after tapping "Done" in this state
