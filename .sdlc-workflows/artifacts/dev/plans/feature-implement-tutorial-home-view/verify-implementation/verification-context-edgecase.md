# Verification Context — Edge Case Scenarios

## Purpose

Define testable edge case scenarios in Given/When/Then format to verify the implementation handles boundary conditions, error states, and non-functional requirements.
This document serves as the single source of truth for edge case verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "cart-ec1-empty", "user-ec2-locked"). No two scenarios should share mutable state.

## Edge Case Scenarios:

### EC 1: AppStorage Default State Integrity

- [ ] **Scenario: Tutorial appears when AppStorage key is absent (fresh install)**
  - Given: User `user-ec1-fresh` has just installed the app and `hasSeenHomeTutorial` key does not exist in `UserDefaults`
  - When: The user authenticates and `HomeView` renders for the first time
  - Then: `AppStorage` resolves `hasSeenHomeTutorial` to its default value of `false`, and `HomeTutorialOverlayView` is displayed with a fade-in animation
  - Verify: Confirm `HomeTutorialOverlayView` is visible; confirm `UserDefaults` does not yet contain the `hasSeenHomeTutorial` key until the user dismisses the overlay

### EC 2: Persistence Survives App Restart

- [ ] **Scenario: Tutorial does not reappear after dismissal and cold app relaunch**
  - Given: User `user-ec2-dismissed` has previously dismissed the tutorial (i.e., `hasSeenHomeTutorial` is `true` in `UserDefaults`)
  - When: The user force-quits and relaunches the app, then authenticates and navigates to `HomeView`
  - Then: `HomeTutorialOverlayView` is never rendered; `HomeView` loads directly without any overlay present
  - Verify: Confirm `UserDefaults` value for `hasSeenHomeTutorial` key (from `WishieConstants`) is `true`; confirm no overlay layer appears in the view hierarchy

### EC 3: Overlay Z-Order with Concurrent Modal Presentations

- [ ] **Scenario: Tutorial overlay does not block or interfere with an open sheet or dialog**
  - Given: User `user-ec3-modal` is on `HomeView` with `hasSeenHomeTutorial = false` and a sheet or dialog is simultaneously presented (e.g., an edit dialog)
  - When: `HomeView` renders with both the tutorial overlay and a modal active
  - Then: The modal/sheet remains interactive and dismissible; the tutorial overlay does not cover or capture gestures from the modal
  - Verify: Confirm the overlay is applied at the `NavigationStack` level, beneath modal presentations; confirm the sheet/dialog receives tap and drag gestures independently of the overlay

### EC 4: Rapid Tap During Fade-Out Animation

- [ ] **Scenario: Multiple rapid taps on overlay do not cause duplicate state writes or animation glitches**
  - Given: User `user-ec4-rapid` is viewing `HomeTutorialOverlayView` and the overlay is currently visible
  - When: The user taps the overlay three times in rapid succession before the fade-out animation completes
  - Then: `hasSeenHomeTutorial` is written to `AppStorage` exactly once; the overlay fades out exactly once without visual stutter, flickering, or re-appearing
  - Verify: Confirm `UserDefaults` write count for the key is 1; confirm the overlay is fully removed from the view hierarchy after a single fade-out cycle

### EC 5: Tutorial Display on Empty Wishlist State

- [ ] **Scenario: Tutorial overlay renders correctly when user has zero wishlists**
  - Given: User `user-ec5-empty` is authenticated with no created or joined wishlists, and `hasSeenHomeTutorial` is `false`
  - When: `HomeView` renders with an empty wishlist list
  - Then: `HomeTutorialOverlayView` is displayed on top of the empty-state content without layout conflicts; all three hint elements (add button, tab selector, swipe gesture) are visible and correctly positioned
  - Verify: Confirm overlay renders without clipping or overflow; confirm all tutorial hint items are visible regardless of the underlying empty wishlist content

### EC 6: AppStorage Key Constant Consistency

- [ ] **Scenario: AppStorage key used in view matches the constant declared in WishieConstants**
  - Given: `WishieConstants` declares a string constant for the `hasSeenHomeTutorial` `AppStorage` key
  - When: The source code for `HomeView` (or its containing view) references this `AppStorage` key
  - Then: The key string referenced in the `@AppStorage` property wrapper exactly matches the constant value in `WishieConstants` — no hardcoded string literals are used
  - Verify: Confirm no raw string literal for the tutorial-seen key exists outside of `WishieConstants`; confirm a single-source-of-truth pattern is followed
