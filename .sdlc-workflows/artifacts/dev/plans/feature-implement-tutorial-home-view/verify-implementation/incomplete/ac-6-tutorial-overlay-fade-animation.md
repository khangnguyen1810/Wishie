# AC 6: Tutorial Overlay Fade Animation

- [ ] **Scenario: Tutorial fades in on first display and fades out on dismissal** ❌ FAILED
  - Given: User "user-ac6-animation" launches the app for the first time (`hasSeenHomeTutorial = false`)
  - When: `HomeView` appears, and then the user taps to dismiss the tutorial
  - Then: The overlay transitions in with a smooth `.easeInOut` fade and transitions out with the same animation on dismissal
  - Verify: No abrupt appearance or disappearance; animation is perceptibly smooth and consistent with `.easeInOut` timing
  - **Failure**: The overlay neither fades in on appearance nor fades out on dismissal — both transitions are abrupt.
  - **Root Cause**:
    1. **Fade-in broken**: `HomeTutorialOverlayView` applies `.animation(.easeInOut(duration: 0.3), value: true)` where `value: true` is a compile-time constant. The `.animation(_:value:)` modifier only fires when the tracked `value` changes; since `true` is always `true`, the animation never triggers and the overlay appears instantly with no fade.
    2. **Fade-out broken**: In `HomeView`, the overlay is inside a plain `if !hasSeenHomeTutorial { ... }` block with no `.transition` modifier and no `withAnimation` wrapper. When `hasSeenHomeTutorial` is set to `true` the view is removed from the hierarchy immediately, producing an abrupt disappearance. A `.transition(.opacity)` modifier on `HomeTutorialOverlayView` inside `HomeView` plus an `withAnimation(.easeInOut(duration: 0.3))` call (or an explicit animation on the `overlay` block) is required.
  - **Affected Files**:
    - `Wishie/CustomView/HomeTutorialOverlayView.swift` — line with `.animation(.easeInOut(duration: 0.3), value: true)`: constant `value` prevents animation from ever firing; needs a state-driven opacity (e.g. `@State private var isVisible = false`, `.opacity(isVisible ? 1 : 0)`, `.onAppear { isVisible = true }`, and `value: isVisible`).
    - `Wishie/Screens/Home/HomeView.swift` — `.overlay { if !hasSeenHomeTutorial { HomeTutorialOverlayView { ... } } }` block: no `.transition(.opacity)` on the child view and no `withAnimation` wrapping `hasSeenHomeTutorial = true`; the removal is unanimated.
  - **Failure**: The overlay appears and disappears abruptly with no fade animation — neither on display nor on dismissal.
  - **Root Cause**:
    1. In `HomeTutorialOverlayView.swift` (line 45), `.animation(.easeInOut(duration: 0.3), value: true)` uses a static constant `true` as the `value`. SwiftUI's `animation(_:value:)` only triggers when the tracked `value` changes — since `true` never changes, this modifier is effectively a no-op and no animation ever fires.
    2. In `HomeView.swift` (lines 247–252), the `.overlay` uses a bare `if !hasSeenHomeTutorial` conditional with no `.transition(.opacity)` modifier and no `withAnimation` wrapper around the `hasSeenHomeTutorial = true` state change. Without a declared transition, SwiftUI removes the view instantly on condition change.
  - **Affected Files**:
    - `Wishie/CustomView/HomeTutorialOverlayView.swift` — line 45: `.animation(.easeInOut(duration: 0.3), value: true)`
    - `Wishie/Screens/Home/HomeView.swift` — lines 247–252: `.overlay { if !hasSeenHomeTutorial { HomeTutorialOverlayView { hasSeenHomeTutorial = true } } }`
