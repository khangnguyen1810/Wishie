# AC 8: Step Transition Animation

- [ ] **Scenario: Advancing between steps animates with easeInOut** ❌ FAILED
  - Given: The coach marks tutorial is active at step 1 for user `user-ac8-animation`
  - When: The user taps the "Next" button to advance to step 2
  - Then: The tooltip and spotlight transition smoothly using `.easeInOut(duration: 0.3)`; no abrupt jump or flash occurs between steps
  - Verify: The `withAnimation(.easeInOut(duration: 0.3))` block wraps the step index increment; the spotlight and tooltip update in sync within the same animation transaction
  - **Failure**: The `onNext` closure in `HomeTutorialOverlayView` uses `withAnimation(.easeInOut(duration: 0.25))` instead of the required `.easeInOut(duration: 0.3)`
  - **Root Cause**: Wrong duration value passed to `withAnimation` — `0.25` was used instead of `0.3`, diverging from the acceptance criteria specification
  - **Affected Files**: `Wishie/CustomView/HomeTutorialOverlayView.swift` — lines 43–47, `onNext` closure inside `CoachMarkOverlayView` initializer
