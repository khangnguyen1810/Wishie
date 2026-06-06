# EC 4: Rapid Tap During Fade-Out Animation

- [ ] **Scenario: Multiple rapid taps on overlay do not cause duplicate state writes or animation glitches** ❌ FAILED
  - Given: User `user-ec4-rapid` is viewing `HomeTutorialOverlayView` and the overlay is currently visible
  - When: The user taps the overlay three times in rapid succession before the fade-out animation completes
  - Then: `hasSeenHomeTutorial` is written to `AppStorage` exactly once; the overlay fades out exactly once without visual stutter, flickering, or re-appearing
  - Verify: Confirm `UserDefaults` write count for the key is 1; confirm the overlay is fully removed from the view hierarchy after a single fade-out cycle
  - **Failure**: Expected `hasSeenHomeTutorial` to be written to `UserDefaults` exactly once, and the overlay to fade out exactly once. Actual: `onDismiss()` can be called multiple times before SwiftUI processes the re-render, causing `UserDefaults.set(true, forKey:)` to be invoked more than once. Additionally, there is no fade-out animation at all — the overlay disappears abruptly.
  - **Root Cause**:
    1. **Duplicate writes**: `HomeTutorialOverlayView` applies `.onTapGesture { onDismiss() }` with no guard, disabled state, or debounce. `@AppStorage` calls `UserDefaults.set(_:forKey:)` unconditionally on every assignment. After tap 1 sets `hasSeenHomeTutorial = true`, SwiftUI schedules a re-render but does not process it synchronously. Taps 2 and 3 arrive before the re-render removes the overlay from the hit-test tree, so `onDismiss()` fires again and writes the same `true` value to `UserDefaults`.
    2. **No fade-out animation**: `.animation(.easeInOut(duration: 0.3), value: true)` uses a constant `Boolean` literal (`true`) as the tracked value. SwiftUI's `animation(_:value:)` only animates when the tracked value _changes_; since `true` never changes, this modifier never triggers. The overlay is removed from the hierarchy abruptly via the `if !hasSeenHomeTutorial` conditional with no transition, producing an instant disappearance rather than a fade-out.
  - **Affected Files**:
    - `Wishie/CustomView/HomeTutorialOverlayView.swift` — `.onTapGesture { onDismiss() }` (no guard); `.animation(.easeInOut(duration: 0.3), value: true)` (constant `value`, animation never fires)
    - `Wishie/Screens/Home/HomeView.swift` — overlay closure `{ hasSeenHomeTutorial = true }` (no idempotency guard; relies on SwiftUI re-render timing alone)
