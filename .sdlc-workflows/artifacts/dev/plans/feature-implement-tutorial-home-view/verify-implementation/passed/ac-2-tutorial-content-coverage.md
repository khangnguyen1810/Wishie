# AC 2: Tutorial Content Coverage

- [x] **Scenario: Tutorial overlay presents hints for all three key interactions**
  - Given: A fresh app installation where `hasSeenHomeTutorial` is `false` for user "user-ac2-content"
  - When: `HomeView` loads and `HomeTutorialOverlayView` is displayed
  - Then: The overlay contains distinct hint elements for the add (+) button, the tab selector, and the swipe-to-delete/leave gesture
  - Verify: Three separate instructional hints are visible within the overlay; no key interaction is omitted

