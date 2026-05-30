# Verification Context — Edge Case Scenarios

## Purpose

Define testable edge case scenarios in Given/When/Then format to verify the implementation handles boundary conditions, error states, and non-functional requirements.
This document serves as the single source of truth for edge case verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "cart-ec1-empty", "user-ec2-locked"). No two scenarios should share mutable state.

## Edge Case Scenarios:

### EC 1: Network Failure During Session Restore

- [ ] **Scenario: Firestore Unavailable During checkToken Defaults to interestsSetup Routing**
  - Given: User `"user-ec1-offline"` is authenticated but Firestore is unreachable when `checkToken()` attempts to fetch `hasCompletedInterestsSetup`
  - When: The app launches and `checkToken()` completes with a network error, causing `getUserInfo()` to resolve with the default `UserModel`
  - Then: `hasCompletedInterestsSetup` defaults to `false`, `RootNavigationCoordinator` routes the app to `AppState.interestsSetup`, and the user lands on `InterestsSelectionView` in onboarding mode
  - Verify: The coordinator state is `AppState.interestsSetup`; `HomeView` is NOT displayed; `InterestsSelectionView` has no back button and no swipe-dismiss gesture

### EC 2: Legacy User Document Missing hasCompletedInterestsSetup Field

- [ ] **Scenario: Legacy User Without Flag Treated as Incomplete Setup**
  - Given: User `"user-ec2-legacy"` has an existing Firestore document that does NOT contain the `hasCompletedInterestsSetup` field (pre-feature document)
  - When: The app launches and `checkToken()` decodes the user document
  - Then: `hasCompletedInterestsSetup` decodes as `false` (the `UserModel` default), and `RootNavigationCoordinator` routes to `AppState.interestsSetup` — identical to a brand-new user
  - Verify: The `InterestsSelectionView` opens with no pre-selected chips; the route is `AppState.interestsSetup`; `HomeView` is NOT shown

### EC 3: Zero Interests Selected on Save (Onboarding Context)

- [ ] **Scenario: Save with Empty Selection Persists Flag and Advances to HomeView**
  - Given: User `"user-ec3-empty-save"` is on `InterestsSelectionView` in onboarding mode (`isOnboarding: true`) with zero hobby chips selected
  - When: The user taps "Save & Continue"
  - Then: A Firestore write persists an empty `interests` array and sets `hasCompletedInterestsSetup = true`; the coordinator transitions to `AppState.authenticated`; `HomeView` is displayed
  - Verify: The Firestore document for `"user-ec3-empty-save"` has `interests: []` and `hasCompletedInterestsSetup: true`; no error alert is shown; `InterestsSelectionView` is dismissed

### EC 4: Firestore Write Failure on Save

- [ ] **Scenario: Firestore Error on Save Surfaces Alert Without Crashing**
  - Given: User `"user-ec4-write-fail"` is on `InterestsSelectionView` with one or more chips selected, and Firestore is configured to reject the write (e.g., network offline or permission denied)
  - When: The user taps "Save & Continue"
  - Then: The view displays an error alert describing the failure; `InterestsSelectionView` remains visible; the coordinator does NOT transition to `AppState.authenticated`; the app does not crash
  - Verify: An error alert is presented; coordinator state remains `AppState.interestsSetup`; `hasCompletedInterestsSetup` is NOT set to `true` in Firestore

### EC 5: Swipe-Dismiss Blocked in Onboarding Context

- [ ] **Scenario: Swipe-Dismiss Gesture Is Disabled During Onboarding**
  - Given: User `"user-ec5-no-swipe"` is on `InterestsSelectionView` in onboarding mode (`isOnboarding: true`)
  - When: The user attempts to swipe down to dismiss the screen
  - Then: The swipe-dismiss gesture is blocked; `InterestsSelectionView` remains presented; no navigation change occurs
  - Verify: No back button appears in the `TopAppBar` left slot; swipe-to-dismiss is programmatically disabled; the only available exit action is the "Save & Continue" button

### EC 6: Back Navigation in Edit Mode Discards Unsaved Changes

- [ ] **Scenario: Back Button in Edit Mode Dismisses Without Persisting Changes**
  - Given: User `"user-ec6-edit-discard"` has previously saved interests `["Gym & Fitness", "Cooking"]`; the user opens `InterestsSelectionView` from `ProfileView` in edit mode (`isOnboarding: false`) and deselects "Cooking" then selects "Hiking"
  - When: The user taps the back button in the `TopAppBar` left slot
  - Then: `InterestsSelectionView` is dismissed via `dismiss()`; no Firestore write is triggered; the user's saved interests remain `["Gym & Fitness", "Cooking"]` in Firestore
  - Verify: The Firestore document for `"user-ec6-edit-discard"` is unchanged; the coordinator state remains `AppState.authenticated`; `ProfileView` is shown

### EC 7: Save Button Bottom Padding on Devices with Home Indicator

- [ ] **Scenario: Save Button Has Visible Bottom Padding and Is Not Obscured by Home Indicator**
  - Given: User `"user-ec7-padding"` opens `InterestsSelectionView` on a device with a home indicator (e.g., iPhone 14 or later)
  - When: The screen fully renders with the "Save & Continue" button visible at the bottom
  - Then: The save button has a bottom padding that prevents it from being flush with or obscured by the home indicator safe area; the button is fully tappable
  - Verify: The button's bottom edge does not overlap the system home indicator region; a consistent bottom padding is visible between the button and the screen edge

### EC 8: Pre-Population of Previously Saved Interests in Edit Mode

- [ ] **Scenario: Edit Mode Opens with Chips Pre-Selected Matching Saved Interests**
  - Given: User `"user-ec8-prepopulate"` has `interests: ["Gym & Fitness", "Painting", "Coffee & Cafes"]` saved in Firestore
  - When: The user opens `InterestsSelectionView` from `ProfileView` in edit mode (`isOnboarding: false`)
  - Then: The chips for "Gym & Fitness", "Painting", and "Coffee & Cafes" are rendered in their selected visual state (scaled to `1.05`, accent color applied); all other chips are unselected
  - Verify: Exactly three chips are in the selected state on screen load; no unintended chips are pre-selected; the selection reflects the Firestore data for `"user-ec8-prepopulate"`

### EC 9: Rapid Chip Tap Toggle Stability

- [ ] **Scenario: Rapidly Tapping the Same Chip Multiple Times Results in Correct Final Toggle State**
  - Given: User `"user-ec9-rapid-tap"` is on `InterestsSelectionView` with the "Gaming" chip in an unselected state
  - When: The user taps the "Gaming" chip five times in rapid succession
  - Then: The chip's selection state accurately reflects an odd number of taps (selected after 1, 3, 5 taps) or even number (unselected after 2, 4 taps); no duplicate entries are added to the selection array; the spring animation completes without visual artefacts
  - Verify: The `selectedInterests` set contains "Gaming" once (not duplicated) after an odd tap count; the chip renders at `scaleEffect(1.05)` in selected state and `scaleEffect(1.0)` in unselected state

### EC 10: Existing Authenticated User Routed to interestsSetup When Flag is False

- [ ] **Scenario: Logged-In User with hasCompletedInterestsSetup False Is Forced Through Setup on App Open**
  - Given: User `"user-ec10-existing-incomplete"` is already authenticated (valid session token) but has `hasCompletedInterestsSetup: false` in their Firestore document
  - When: The app launches and `checkToken()` successfully fetches the user document
  - Then: `RootNavigationCoordinator` reads `hasCompletedInterestsSetup = false` and routes to `AppState.interestsSetup`; `HomeView` is NOT presented; `InterestsSelectionView` opens in onboarding mode
  - Verify: Coordinator state is `AppState.interestsSetup`; `InterestsSelectionView` has no back button; chips are pre-selected if the user had previously saved a partial `interests` array

### EC 11: Successful Save in Edit Mode Does Not Trigger Coordinator State Transition

- [ ] **Scenario: Saving Interests in Edit Mode Dismisses View Without Advancing Coordinator State**
  - Given: User `"user-ec11-edit-save"` is authenticated (`AppState.authenticated`) and opens `InterestsSelectionView` from `ProfileView` in edit mode (`isOnboarding: false`) with chips "Reading" and "Yoga" selected
  - When: The user taps the save action
  - Then: Firestore is updated with the new interests; `InterestsSelectionView` is dismissed via `dismiss()`; the coordinator state remains `AppState.authenticated`; no navigation to HomeView restart occurs
  - Verify: The coordinator state is unchanged at `AppState.authenticated`; `ProfileView` is shown after dismissal; the Firestore document for `"user-ec11-edit-save"` contains the updated interests
