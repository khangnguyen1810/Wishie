implement-home-view-onboarding-tutorial

# Requirement Context

## Current State

`HomeView` is the primary authenticated screen rendered by `MainView` when `AppState` is `.authenticated`. It displays the user's wishlists and friends' wishlists via a tab selector. There is no tutorial or first-launch guidance for new users — the screen renders immediately after authentication without any contextual instruction about available interactions.

## Goals

- Display a one-time tutorial overlay on `HomeView` the first time a user sees it after installation.
- Educate the user about the three key interactions: creating/joining a wishlist (add button), switching between tabs, and swiping to delete or leave a wishlist.
- Persist the tutorial-seen state so the tutorial never appears again after the first dismissal.
- Allow the user to dismiss the tutorial by tapping anywhere on the overlay.

## Risk & Mitigation

- **Risk**: `AppStorage` default value mismatch causing tutorial to always or never show. **Mitigation**: Use `false` as the default for `hasSeenHomeTutorial`, meaning tutorial shows until explicitly dismissed and persisted as `true`.
- **Risk**: Tutorial overlay blocking dialogs or sheets already presented. **Mitigation**: Apply the overlay at the outermost `NavigationStack` level so it appears above screen content but the existing `.sheet`, `.fullScreenCover`, and dialog modifiers remain unaffected.

# Technical Specification Context

## Functional Requirements:

- System MUST display `HomeTutorialOverlayView` on `HomeView` when `hasSeenHomeTutorial` is `false`.
- System MUST dismiss the tutorial overlay when the user taps anywhere on it.
- System MUST persist `hasSeenHomeTutorial = true` via `AppStorage` upon dismissal so the tutorial does not reappear on subsequent launches.
- System MUST NOT show the tutorial overlay on any app launch after it has been dismissed once.
- System MUST present tutorial hints covering the three key interactions: the add (+) button, the tab selector, and the swipe-to-delete/leave gesture.
- System MUST store the `hasSeenHomeTutorial` `AppStorage` key string as a constant in `WishieConstants`.

## Non-Functional Requirements:

- Tutorial overlay MUST fade in and fade out with a smooth `.easeInOut` animation.
- Tutorial overlay MUST render above all `HomeView` content without disrupting the navigation stack or modal presentations.
- Tutorial card design MUST align with the app's established visual language: warm yellow/gold gradient backgrounds, `wishies` fonts, and `Color(hex:)` styled elements.
