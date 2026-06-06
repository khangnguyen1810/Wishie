# AC 1: First-Launch Tutorial Display

- [x] **Scenario: Tutorial overlay appears on HomeView for a first-time user**
  - Given: A fresh app installation where `hasSeenHomeTutorial` is `false` for user "user-ac1-first-launch"
  - When: The authenticated user navigates to `HomeView` for the first time
  - Then: `HomeTutorialOverlayView` is rendered and visible above all `HomeView` content
  - Verify: The overlay is present in the view hierarchy; `HomeView` content (wishlists, tab selector) is still visible underneath the overlay
