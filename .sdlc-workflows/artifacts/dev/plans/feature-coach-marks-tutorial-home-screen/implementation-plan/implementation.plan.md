implement-coach-marks-tutorial-home-screen

# Requirement Context

## Current State

The Home screen has a basic modal overlay tutorial (`HomeTutorialOverlayView` in `Wishie/CustomView/HomeTutorialOverlayView.swift`) that shows all three app hints simultaneously in a single card dialog. It is triggered once on first app launch via `@AppStorage(WishieConstants.hasSeenHomeTutorial)` in `HomeView`. The overlay uses a tap-to-dismiss pattern with a fade animation and does not contextually highlight specific UI elements.

## Goals

- Replace the all-at-once hint card with a step-by-step Coach Marks tutorial that spotlights individual UI elements on the Home screen
- Highlight three key elements in sequence: the add (+) button in the top bar, the tab selector, and a swipe gesture hint (no specific element)
- Introduce a reusable coach mark rendering infrastructure (`CoachMarkOverlayView`, `CoachMarkStep`, `CoachMarkBoundsKey`) that can be extended to other screens

## Risk & Mitigation

- **Anchor resolution timing**: `Anchor<CGRect>` values must be resolved inside a `GeometryProxy` context — mitigated by containing the resolution inside `HomeTutorialOverlayView`'s own `GeometryReader`
- **Safe area offsets**: Overlay uses `.ignoresSafeArea()` to prevent spotlight misalignment
- **Empty list state**: Step 3 (swipe hint) has no associated anchor (`anchorID: nil`), rendering a centered tooltip with no spotlight — avoiding crashes when the list is empty on first launch

# Technical Specification Context

## Functional Requirements:

- System MUST display a step-by-step coach marks tutorial on first launch of the Home screen
- System MUST spotlight the add (+) button (gold circle in top bar) in step 1 with tooltip: title "Create or Join", message explaining the button's purpose
- System MUST spotlight the tab selector `HStack` in step 2 with tooltip: title "Your Lists", message explaining tab switching
- System MUST display a swipe gesture hint in step 3 without a spotlight (centered tooltip): title "Swipe to Manage", message explaining swipe-left behavior
- System MUST persist tutorial completion state using `AppStorage` with key `WishieConstants.hasSeenHomeTutorial` (unchanged)
- System MUST navigate between steps with a "Next" button and present a "Done" button on the final step
- System MUST dim all non-highlighted UI when a step with a spotlight is active
- System MUST animate the entrance/exit of each step with `.easeInOut(duration: 0.3)`

## Non-Functional Requirements:

- System MUST render the spotlight cutout using a SwiftUI `Path` with `FillStyle(eoFill: true)` (even-odd fill rule) for correct hole punching through the dim overlay
- System MUST capture element positions using `CoachMarkBoundsKey: PreferenceKey` with `[String: Anchor<CGRect>]` without disrupting existing layout geometry
- System MUST resolve `Anchor<CGRect>` to `CGRect` inside a `GeometryReader` within `HomeTutorialOverlayView`, avoiding any layout ambiguity from passing `GeometryProxy` across view boundaries
