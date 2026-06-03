# AC 7: HomeView — App Store-Style Zoom Transition

- [x] **Scenario: Tapping a My List card zooms into WishlistDetailScreen with card-matched origin**
  - Given: `HomeView` is rendered for user `"user-ac7-zoom-mylist"` with at least one wishlist in `myWishlists`, and the `"My List"` tab is active
  - When: the user taps the `HomeItemViewCell` card for wishlist `"wishlist-ac7-zoom-mylist"`
  - Then: `WishlistDetailScreen` appears via a zoom animation that originates from the exact bounds of the tapped card; the detail screen expands from the card's position and size on screen
  - Verify: `.matchedTransitionSource(id: wishlist.0.id, in: animation)` is applied to the card's `ZStack` container in the `myList` `ForEach` loop; the destination view carries `.navigationTransition(.zoom(sourceID: wishlist.0.id, in: animation))`; the transition is not a default push/slide animation

- [x] **Scenario: Tapping a Friend's List card zooms into WishlistDetailScreen with card-matched origin**
  - Given: `HomeView` is rendered for user `"user-ac7-zoom-friendslist"` with at least one entry in `myFriendWishlists`, and the `"Friend's List"` tab is active
  - When: the user taps the `HomeItemViewCell` card for wishlist `"wishlist-ac7-zoom-friendslist"`
  - Then: `WishlistDetailScreen` appears via a zoom animation that originates from the exact bounds of the tapped card in the Friend's List `ForEach`
  - Verify: `.matchedTransitionSource(id: wishlist.0.id, in: animation)` is applied to the card's `ZStack` container in the `friendsList` `ForEach` loop; same `animation` namespace is used as in `myList`; zoom origin matches the Friend's List card position, not any My List card

- [x] **Scenario: Existing @Namespace animation is reused — no additional namespace declared**
  - Given: `HomeView` is inspected for `"user-ac7-namespace"` with both tabs populated
  - When: the zoom transitions for both `myList` and `friendsList` cards are wired up
  - Then: both `.matchedTransitionSource` call sites reference the single `@Namespace private var animation` already declared in `HomeView`; no second `@Namespace` property is introduced
  - Verify: `HomeView` contains exactly one `@Namespace private var animation` declaration; both `ForEach` bodies pass `in: animation` to `.matchedTransitionSource`; the destination `WishlistDetailScreen` receives the same namespace value via its transition modifier

- [x] **Scenario: matchedTransitionSource is scoped to the card ZStack, not the NavigationLink**
  - Given: `HomeView` renders a wishlist card `"wishlist-ac7-scope"` for user `"user-ac7-scope"` in the `myList` view
  - When: the view hierarchy of the `ForEach` item is examined
  - Then: `.matchedTransitionSource(id:in:)` is attached directly to the outermost card container `ZStack` wrapping `HomeItemViewCell`; the hidden `NavigationLink` and its `label` closure do not carry the modifier
  - Verify: the visual zoom origin aligns with the full card rectangle; no unexpected geometry mismatch between the card's visual frame and the zoom source bounds; `swipeActions` and other card modifiers are unaffected
