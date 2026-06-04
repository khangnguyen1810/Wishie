# EC 5: Tutorial Display on Empty Wishlist State

- [x] **Scenario: Tutorial overlay renders correctly when user has zero wishlists**
  - Given: User `user-ec5-empty` is authenticated with no created or joined wishlists, and `hasSeenHomeTutorial` is `false`
  - When: `HomeView` renders with an empty wishlist list
  - Then: `HomeTutorialOverlayView` is displayed on top of the empty-state content without layout conflicts; all three hint elements (add button, tab selector, swipe gesture) are visible and correctly positioned
  - Verify: Confirm overlay renders without clipping or overflow; confirm all tutorial hint items are visible regardless of the underlying empty wishlist content
