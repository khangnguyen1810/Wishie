# EC 5: Swipe-Dismiss Blocked in Onboarding Context

- [ ] **Scenario: Swipe-Dismiss Gesture Is Disabled During Onboarding** ❌ FAILED
  - Given: User `"user-ec5-no-swipe"` is on `InterestsSelectionView` in onboarding mode (`isOnboarding: true`)
  - When: The user attempts to swipe down to dismiss the screen
  - Then: The swipe-dismiss gesture is blocked; `InterestsSelectionView` remains presented; no navigation change occurs
  - Verify: No back button appears in the `TopAppBar` left slot; swipe-to-dismiss is programmatically disabled; the only available exit action is the "Save & Continue" button
  - **Failure**: Two explicit criteria are unmet:
    1. The scenario's Given condition references `isOnboarding: true` but `InterestsSelectionView.init()` accepts no parameters — no onboarding mode flag exists.
    2. "swipe-to-dismiss is programmatically disabled" is not satisfied — there is no `.interactiveDismissDisabled(true)` or equivalent modifier anywhere in the view.
  - **Root Cause**: The implementation prevents swipe-dismiss architecturally (the view is rendered inside a `ZStack` via state-based navigation in `MainView`, never as a sheet), but this is an implicit structural side-effect rather than an explicit programmatic control. The scenario expected a distinct `isOnboarding` parameter and explicit `.interactiveDismissDisabled(true)` enforcement so future code changes (e.g., presenting the view as a sheet in a profile-edit flow) would not accidentally re-enable swipe-dismiss.
  - **Affected Files**:
    - `Wishie/Screens/Interests/InterestsSelectionView.swift` — `init()` has no `isOnboarding` parameter; no `.interactiveDismissDisabled()` modifier applied anywhere in `body`
    - `Wishie/Screens/MainView.swift` line 24–27 — sole presentation site; uses `ZStack` state switch, not `.sheet()`
