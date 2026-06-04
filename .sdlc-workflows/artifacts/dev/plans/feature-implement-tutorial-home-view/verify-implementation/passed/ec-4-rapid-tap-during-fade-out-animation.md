# EC 4: Rapid Tap During Fade-Out Animation

- [x] **Scenario: Multiple rapid taps on overlay do not cause duplicate state writes or animation glitches** ✅ RESOLVED
  - Given: User `user-ec4-rapid` is viewing `HomeTutorialOverlayView` and the overlay is currently visible
  - When: The user taps the overlay three times in rapid succession before the fade-out animation completes
  - Then: `hasSeenHomeTutorial` is written to `AppStorage` exactly once; the overlay fades out exactly once without visual stutter, flickering, or re-appearing
  - Verify: Confirm `UserDefaults` write count for the key is 1; confirm the overlay is fully removed from the view hierarchy after a single fade-out cycle
  - ✅ RESOLVED: Added `guard isVisible else { return }` in the tap handler to block all subsequent taps once dismissal begins. `isVisible` is set to `false` immediately on the first valid tap, driving the `.easeInOut(duration: 0.3)` fade-out animation (the tracked value now changes from `true` → `false`). `onDismiss()` is deferred via `DispatchQueue.main.asyncAfter(deadline: .now() + 0.3)` so `hasSeenHomeTutorial` is written to `AppStorage` exactly once — only after the animation completes.
  - **Affected Files**:
    - `Wishie/CustomView/HomeTutorialOverlayView.swift` — Replaced `.onTapGesture { onDismiss() }` with a guarded handler that sets `isVisible = false` (triggering the fade-out) then calls `onDismiss()` after 0.3 s delay
