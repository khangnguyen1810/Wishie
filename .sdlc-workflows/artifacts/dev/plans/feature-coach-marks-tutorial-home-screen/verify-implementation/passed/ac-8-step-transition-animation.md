# AC 8: Step Transition Animation

- [x] **Scenario: Advancing between steps animates with easeInOut** ✅ RESOLVED
  - Given: The coach marks tutorial is active at step 1 for user `user-ac8-animation`
  - When: The user taps the "Next" button to advance to step 2
  - Then: The tooltip and spotlight transition smoothly using `.easeInOut(duration: 0.3)`; no abrupt jump or flash occurs between steps
  - Verify: The `withAnimation(.easeInOut(duration: 0.3))` block wraps the step index increment; the spotlight and tooltip update in sync within the same animation transaction
  - **Resolution**: Updated `withAnimation` duration in the `onNext` closure in `HomeTutorialOverlayView.swift` from `0.25` to `0.3` to match the acceptance criteria specification.
  - **Affected Files**: `Wishie/CustomView/HomeTutorialOverlayView.swift` — `onNext` closure inside `CoachMarkOverlayView` initializer
