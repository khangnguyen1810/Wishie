# AC 5: Owner Swipe-to-Delete

- [x] **Scenario: Swipe-to-delete action is available on unpicked item rows for the owner**
  - Given: A wishlist `wishlist-ac5-swipe` is owned by the logged-in user and contains an unpicked item `item-ac5-swipeable`
  - When: The owner swipes left on the row for `item-ac5-swipeable`
  - Then: A destructive "Delete" swipe action button is revealed
  - Verify: The swipe action is implemented via native SwiftUI `List` `.swipeActions`; the action button is labeled "Delete" with a destructive style; items implemented as a `List` not a `ForEach`-in-`VStack`

- [x] **Scenario: Swipe-to-delete triggers confirmation dialog before deletion**
  - Given: A wishlist `wishlist-ac5-swipe-confirm` is owned by the logged-in user; the owner has swiped to reveal the "Delete" action on `item-ac5-confirm`
  - When: The owner taps the "Delete" swipe action button
  - Then: A confirmation dialog is presented before any backend call is made; confirming deletes the item; canceling dismisses the dialog with no changes
  - Verify: The dialog appears before `deleteWishlistItem` is called; item remains in the list if the user cancels

---

