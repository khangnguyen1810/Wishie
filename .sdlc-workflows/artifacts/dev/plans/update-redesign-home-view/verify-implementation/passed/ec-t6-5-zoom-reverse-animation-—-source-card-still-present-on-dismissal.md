# EC-T6-5: Zoom Reverse Animation — Source Card Still Present on Dismissal

- [x] **Scenario: Dismissing WishlistDetailScreen zooms back into the correct source card without layout jump**
  - Given: `homeViewModel.myWishlists` contains 'wishlist-t6ec5-back-nav' at list position 2; the user has tapped it, triggering the zoom-in transition
  - When: `WishlistDetailScreen` is presented and the user performs the interactive back gesture (swipe-from-left-edge or back button)
  - Then: The zoom-out reverse animation correctly targets the card at its original position in the `List`; the card does not appear to snap from a different position; the `HomeView` list scroll offset is preserved so the source card is visible upon return
  - Verify: The `@Namespace private var animation` namespace is the same instance used for both `.matchedTransitionSource` (source) and `.navigationTransition(.zoom(sourceID:in:))` (destination); list scroll position is unchanged after back navigation
