# EC 6: Animation Performance Boundary

- [x] **Scenario: State transition animation exceeds 500ms threshold**
  - Given: Device `device-ec6-slow` is under CPU-heavy load and `appState` is `.unauthenticated`
  - When: A successful login triggers `appState` to transition to `.authenticated(userId: "user-ec6-perf")` and the `authToHome` animation (`.move(edge: .trailing).combined(with: .opacity)`) begins
  - Then: The animation is driven by the SwiftUI animation system and completes within 500ms regardless of device load; the `.easeInOut(duration: 0.4)` timing ensures the total transition does not exceed the 400ms budget plus render overhead
  - Verify: Animation duration is configured to ≤ 400ms (`defaultDuration = 0.4`); no jank or skipped frames are observable; `HomeView` is fully rendered and interactive after transition completes

- [x] **Scenario: `RootNavigationAnimations.animationFor` called with an undefined transition tuple**
  - Given: `RootNavigationAnimations.animationFor(transition:)` is invoked with a transition not explicitly mapped (e.g., `.welcome` → `.authenticated` skipping `.unauthenticated`)
  - When: The pattern match in `animationFor` finds no matching case
  - Then: The fallback animation `.easeInOut(duration: 0.4)` is returned; the transition still completes smoothly without crashing
  - Verify: No `fatalError` or crash; a valid `Animation` value is always returned; transition completes visually within 500ms

---
