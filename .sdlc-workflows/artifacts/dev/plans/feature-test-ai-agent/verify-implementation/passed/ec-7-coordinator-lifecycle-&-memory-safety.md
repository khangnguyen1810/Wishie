# EC 7: Coordinator Lifecycle & Memory Safety

- [x] **Scenario: `RootNavigationCoordinator` is deallocated while a state update is in-flight**
  - Given: `RootNavigationCoordinator` for `user-ec7-dealloc` is mid-transition with a Combine subscription active
  - When: The coordinator is deallocated (e.g., parent view removed) before the async state update on `DispatchQueue.main` completes
  - Then: The weak reference pattern and cancellables cleanup in `deinit` prevent a dangling reference; no `EXC_BAD_ACCESS` crash occurs
  - Verify: `cancellables` are cleared in `deinit`; any queued `DispatchQueue.main` closures referencing `[weak self]` safely no-op; no memory leak is reported by Instruments

- [x] **Scenario: Multiple `completeOnboarding()` calls in rapid succession** ✅ RESOLVED
  - Given: `RootNavigationCoordinator` for `user-ec7-rapid-onboard` has `appState == .welcome` and `hasCompletedOnboarding = false`
  - When: `completeOnboarding()` is called three times within 100ms (e.g., triple-tap or test race condition)
  - Then: `hasCompletedOnboarding` is set to `true` on the first call; subsequent calls are idempotent; `deriveAppState()` emits at most one meaningful state change; `appState` transitions to `.unauthenticated` exactly once
  - Verify: `appState == .unauthenticated` after all calls; no duplicate animation triggers; `objectWillChange.send()` is not called redundantly if state did not change
  - **Resolution**: Added an equality guard in `completeOnboarding()`: the new state is derived first, then compared against the current `appState` using `Equatable` conformance (inherited from `Hashable`). `appState` is only assigned if the value differs, preventing `@Published` `willSet` from firing `objectWillChange.send()` on redundant same-value assignments. Subsequent calls with an already-set `hasCompletedOnboarding` will derive the same `.unauthenticated` state and skip the assignment entirely.
  - **Fix Applied**: [Wishie/Coordinator/RootNavigationCoordinator.swift](Wishie/Coordinator/RootNavigationCoordinator.swift) — `completeOnboarding()` now derives `newState`, guards with `if newState != appState`, and assigns only on change.
