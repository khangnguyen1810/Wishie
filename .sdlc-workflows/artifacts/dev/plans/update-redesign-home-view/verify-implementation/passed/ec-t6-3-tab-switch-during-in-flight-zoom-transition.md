# EC-T6-3: Tab Switch During In-Flight Zoom Transition

- [x] **Scenario: Switching tabs while the zoom transition is animating does not orphan the source card geometry**
  - Given: Both `myList` and `friendsList` tabs are populated; the user is viewing the `myList` tab
  - When: The user taps a 'wishlist-t6ec3-tab-switch' card (initiating the zoom-in animation) and simultaneously or immediately after taps the `friendsList` tab pill before `WishlistDetailScreen` finishes appearing
  - Then: The zoom animation completes without visual tearing; `WishlistDetailScreen` appears fully; on dismissal the zoom-out reverse animation resolves without crashing even if the source card is no longer in the active tab's list
  - Verify: No `matchedGeometryEffect` assertion failure or purple runtime warning is emitted; the app remains interactive after the transition sequence completes

