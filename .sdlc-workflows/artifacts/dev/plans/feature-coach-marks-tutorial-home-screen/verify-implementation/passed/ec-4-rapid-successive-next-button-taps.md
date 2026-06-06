# EC 4: Rapid Successive "Next" Button Taps

- [x] **Scenario: Multiple rapid taps on "Next" do not skip steps or corrupt step index** ✅ RESOLVED
  - Given: User 'user-ec4-rapid' is on step 1 of the coach marks tutorial with the "Next" button visible
  - When: The user taps "Next" three times in rapid succession before the `.easeInOut(duration: 0.3)` transition completes
  - Then: The tutorial advances by exactly one step per intentional tap; the `currentStep` index does not exceed the bounds of the `CoachMarkStep` array; no index-out-of-range crash occurs
  - Verify: Confirm step index is clamped or guarded; confirm the final displayed step does not exceed index 2
  - **Failure**: No upper-bound guard exists on `currentStep` in the `onNext` closure; rapid successive taps before a SwiftUI re-render cycle can increment `currentStep` beyond `steps.count - 1` (index 2), causing a fatal array-index-out-of-bounds crash at `steps[currentStep]`
  - **Root Cause**: The `onNext` closure in `HomeTutorialOverlayView` unconditionally increments `currentStep += 1` with no bounds check. The only guard is in `CoachMarkOverlayView.actionButton` (`if stepIndex < totalSteps - 1`), but `stepIndex` is a stale `let` prop captured at the last render — if multiple taps are queued before SwiftUI processes a re-render, `stepIndex` remains 0 for all taps, `0 < 2` passes each time, and `currentStep` can reach 3. `steps[3]` on a 3-element array crashes immediately. No debounce, throttle, or `.disabled()` guard is applied during the transition.
  - ✅ RESOLVED: Applied two targeted fixes in `HomeTutorialOverlayView`:
    1. `onNext` closure: changed `currentStep += 1` to `currentStep = min(currentStep + 1, steps.count - 1)` — regardless of how many rapid taps fire before a SwiftUI re-render, the clamped assignment ensures `currentStep` never exceeds `steps.count - 1` (index 2).
    2. Body subscript: changed `steps[currentStep]` to `steps[min(currentStep, steps.count - 1)]` — eliminates the fatal index-out-of-bounds crash even if `currentStep` were transiently stale.
  - **Affected Files**:
    - [Wishie/CustomView/HomeTutorialOverlayView.swift](../../../../../Wishie/CustomView/HomeTutorialOverlayView.swift) — `onNext` closure: `currentStep = min(currentStep + 1, steps.count - 1)` (clamped increment)
    - [Wishie/CustomView/HomeTutorialOverlayView.swift](../../../../../Wishie/CustomView/HomeTutorialOverlayView.swift) — view body: `steps[min(currentStep, steps.count - 1)]` (safe subscript)
    - [Wishie/CustomView/CoachMarkOverlayView.swift](../../../../../Wishie/CustomView/CoachMarkOverlayView.swift) — no change required; the stale-prop risk is fully mitigated by the clamped increment above

