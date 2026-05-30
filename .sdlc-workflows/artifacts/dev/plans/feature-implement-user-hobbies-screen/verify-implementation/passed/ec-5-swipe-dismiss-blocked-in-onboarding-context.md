# EC 5: Swipe-Dismiss Blocked in Onboarding Context

- [x] **Scenario: Swipe-Dismiss Gesture Is Disabled During Onboarding** ✅ RESOLVED
  - Given: User `"user-ec5-no-swipe"` is on `InterestsSelectionView` in onboarding mode (`isOnboarding: true`)
  - When: The user attempts to swipe down to dismiss the screen
  - Then: The swipe-dismiss gesture is blocked; `InterestsSelectionView` remains presented; no navigation change occurs
  - Verify: No back button appears in the `TopAppBar` left slot; swipe-to-dismiss is programmatically disabled; the only available exit action is the "Save & Continue" button
  - **Resolution**:
    1. Added `private let isOnboarding: Bool` property and `init(isOnboarding: Bool = false)` parameter to `InterestsSelectionView` so the onboarding context is explicitly declared.
    2. Applied `.interactiveDismissDisabled(isOnboarding)` modifier on the view body to programmatically block swipe-dismiss when in onboarding mode.
    3. Updated `MainView` to pass `isOnboarding: true` when presenting `InterestsSelectionView` for the `.interestsSetup` state.
    4. Added `.padding(.bottom, 16)` to the Save button so it does not stick to the bottom edge of the screen.
  - **Affected Files**:
    - `Wishie/Screens/Interests/InterestsSelectionView.swift` — added `isOnboarding` parameter, `.interactiveDismissDisabled(isOnboarding)` modifier, and `.padding(.bottom, 16)` on Save button
    - `Wishie/Screens/MainView.swift` — updated `InterestsSelectionView()` call to `InterestsSelectionView(isOnboarding: true)`

