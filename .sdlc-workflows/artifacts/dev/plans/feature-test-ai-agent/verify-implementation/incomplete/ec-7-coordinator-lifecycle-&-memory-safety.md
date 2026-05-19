# EC 7: Coordinator Lifecycle & Memory Safety

- [x] **Scenario: `RootNavigationCoordinator` is deallocated while a state update is in-flight**
  - Given: `RootNavigationCoordinator` for `user-ec7-dealloc` is mid-transition with a Combine subscription active
  - When: The coordinator is deallocated (e.g., parent view removed) before the async state update on `DispatchQueue.main` completes
  - Then: The weak reference pattern and cancellables cleanup in `deinit` prevent a dangling reference; no `EXC_BAD_ACCESS` crash occurs
  - Verify: `cancellables` are cleared in `deinit`; any queued `DispatchQueue.main` closures referencing `[weak self]` safely no-op; no memory leak is reported by Instruments

- [ ] **Scenario: Multiple `completeOnboarding()` calls in rapid succession** ❌ FAILED
  - Given: `RootNavigationCoordinator` for `user-ec7-rapid-onboard` has `appState == .welcome` and `hasCompletedOnboarding = false`
  - When: `completeOnboarding()` is called three times within 100ms (e.g., triple-tap or test race condition)
  - Then: `hasCompletedOnboarding` is set to `true` on the first call; subsequent calls are idempotent; `deriveAppState()` emits at most one meaningful state change; `appState` transitions to `.unauthenticated` exactly once
  - Verify: `appState == .unauthenticated` after all calls; no duplicate animation triggers; `objectWillChange.send()` is not called redundantly if state did not change
  - **Failure**: `objectWillChange.send()` is called on every invocation regardless of whether `appState` changed; `appState` is re-assigned `.unauthenticated` on the 2nd and 3rd calls even though it is already `.unauthenticated`, triggering redundant publisher emissions and potential duplicate animation triggers.
  - **Root Cause**: `completeOnboarding()` unconditionally assigns `appState = deriveAppState()` without guarding against a no-change assignment. Swift's `@Published` property wrapper fires `objectWillChange.send()` via `willSet` on every assignment regardless of value equality — there is no built-in idempotency check. `AppState` conforms to `Hashable` (and therefore `Equatable`), but this conformance is never used to short-circuit the assignment.
  - **Affected Files**: [Wishie/Coordinator/RootNavigationCoordinator.swift](Wishie/Coordinator/RootNavigationCoordinator.swift) — `completeOnboarding()` method (lines 20–23). The fix requires guarding the assignment: derive the new state first, compare with the current `appState`, and only assign if they differ.
