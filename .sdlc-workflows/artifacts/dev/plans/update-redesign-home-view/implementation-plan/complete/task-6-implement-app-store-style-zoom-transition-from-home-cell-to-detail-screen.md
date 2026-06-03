# Task 6: Implement App Store-Style Zoom Transition from Home Cell to Detail Screen

- [ ] 6.1: In `Wishie/Screens/Home/HomeView.swift` UPDATE both `ForEach` loops inside the `List` (`myList` case and `friendsList` case):
  - Add `.matchedTransitionSource(id: wishlist.0.id, in: animation)` as a modifier on the card `ZStack` (the outer `ZStack` that wraps the hidden `NavigationLink` and `HomeItemViewCell`) in BOTH the `myList` and `friendsList` `ForEach` closures.
  - Place this modifier immediately after `.contentShape(Rectangle())` and before `.listRowSeparator(.hidden)`.
  - The existing `@Namespace private var animation` and `.navigationTransition(.zoom(sourceID: wishlist.0.id, in: animation))` on `WishlistDetailScreen` remain unchanged — no new namespace or destination modifier is required.
  - The `id` passed to `.matchedTransitionSource` must be `wishlist.0.id` (a `String`) — matching the `sourceID` already used in `.navigationTransition(.zoom(sourceID: wishlist.0.id, in: animation))`.
  - Do not apply `.matchedTransitionSource` to `HomeItemViewCell` directly or to the hidden `NavigationLink`; apply it only to the outer `ZStack` so the full card bounds define the zoom geometry.
