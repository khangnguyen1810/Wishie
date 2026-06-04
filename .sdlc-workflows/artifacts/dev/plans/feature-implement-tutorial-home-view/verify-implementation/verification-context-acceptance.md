# Verification Context — Acceptance Scenarios

## Purpose

Define testable acceptance scenarios in Given/When/Then format to verify the implementation meets functional requirements and success criteria.
This document serves as the single source of truth for acceptance verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "user-ac1-login", "product-ac2-checkout"). No two scenarios should share mutable state.

## Acceptance Scenarios:

### AC 1: First-Launch Tutorial Display

- [ ] **Scenario: Tutorial overlay appears on HomeView for a first-time user**
  - Given: A fresh app installation where `hasSeenHomeTutorial` is `false` for user "user-ac1-first-launch"
  - When: The authenticated user navigates to `HomeView` for the first time
  - Then: `HomeTutorialOverlayView` is rendered and visible above all `HomeView` content
  - Verify: The overlay is present in the view hierarchy; `HomeView` content (wishlists, tab selector) is still visible underneath the overlay

### AC 2: Tutorial Content Coverage

- [ ] **Scenario: Tutorial overlay presents hints for all three key interactions**
  - Given: A fresh app installation where `hasSeenHomeTutorial` is `false` for user "user-ac2-content"
  - When: `HomeView` loads and `HomeTutorialOverlayView` is displayed
  - Then: The overlay contains distinct hint elements for the add (+) button, the tab selector, and the swipe-to-delete/leave gesture
  - Verify: Three separate instructional hints are visible within the overlay; no key interaction is omitted

### AC 3: Tap-to-Dismiss Tutorial

- [ ] **Scenario: Tapping anywhere on the tutorial overlay dismisses it**
  - Given: User "user-ac3-tap-dismiss" is authenticated and viewing `HomeView` with `HomeTutorialOverlayView` visible (`hasSeenHomeTutorial = false`)
  - When: The user taps anywhere on the tutorial overlay
  - Then: The tutorial overlay is dismissed and is no longer visible on screen
  - Verify: `HomeTutorialOverlayView` is removed from the view hierarchy after the tap gesture is detected; `HomeView` content is fully interactive

### AC 4: Tutorial Persistence After Dismissal

- [ ] **Scenario: `hasSeenHomeTutorial` is persisted as `true` upon dismissal**
  - Given: User "user-ac4-persistence" taps to dismiss the tutorial on `HomeView`
  - When: The dismissal action is triggered
  - Then: `AppStorage` key `hasSeenHomeTutorial` is set to `true` and stored on device
  - Verify: Reading `AppStorage["hasSeenHomeTutorial"]` returns `true` immediately after dismissal; the value survives an app restart

### AC 5: Tutorial Does Not Reappear on Subsequent Launches

- [ ] **Scenario: Tutorial overlay is not shown after it has been dismissed once**
  - Given: User "user-ac5-no-repeat" has previously dismissed the tutorial (`hasSeenHomeTutorial = true` in `AppStorage`)
  - When: The user relaunches the app and `HomeView` is presented
  - Then: `HomeTutorialOverlayView` is not displayed
  - Verify: The overlay view is absent from the view hierarchy on every subsequent app launch; `HomeView` renders normally without any tutorial layer

### AC 6: Tutorial Overlay Fade Animation

- [ ] **Scenario: Tutorial fades in on first display and fades out on dismissal**
  - Given: User "user-ac6-animation" launches the app for the first time (`hasSeenHomeTutorial = false`)
  - When: `HomeView` appears, and then the user taps to dismiss the tutorial
  - Then: The overlay transitions in with a smooth `.easeInOut` fade and transitions out with the same animation on dismissal
  - Verify: No abrupt appearance or disappearance; animation is perceptibly smooth and consistent with `.easeInOut` timing

### AC 7: AppStorage Key Defined in WishieConstants

- [ ] **Scenario: `hasSeenHomeTutorial` AppStorage key is sourced from `WishieConstants`**
  - Given: The implementation of tutorial visibility logic for user "user-ac7-constants"
  - When: The `@AppStorage` property for `hasSeenHomeTutorial` is declared in code
  - Then: The key string references a constant defined in `WishieConstants` rather than an inline string literal
  - Verify: `WishieConstants` contains a constant for the `hasSeenHomeTutorial` key; the `@AppStorage` declaration in the tutorial-related view or view model uses that constant

### AC 8: Tutorial Overlay Renders Above Content Without Disrupting Navigation

- [ ] **Scenario: Tutorial overlay does not block sheet, full-screen cover, or dialog presentations**
  - Given: User "user-ac8-overlay-layer" is on `HomeView` with the tutorial overlay visible
  - When: A sheet, full-screen cover, or dialog is triggered from within `HomeView`
  - Then: The modal presentation renders above the tutorial overlay and behaves normally
  - Verify: `.sheet`, `.fullScreenCover`, and dialog modifiers function correctly while the tutorial is visible; the navigation stack is not disrupted
