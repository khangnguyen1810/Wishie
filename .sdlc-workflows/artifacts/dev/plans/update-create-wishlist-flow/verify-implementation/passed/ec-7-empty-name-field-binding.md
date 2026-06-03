# EC 7: Empty Name Field Binding

- [x] **Scenario: Leaving the name field empty preserves an empty string in the model without crashing**
  - Given: WishlistItemCard 'item-ec7-emptyname' has an empty string bound to `WishlistItem.name` (user cleared the field)
  - When: The user taps outside the field or navigates to another card
  - Then: The empty string is preserved in the bound `WishlistItem` without any crash, nil coalescing error, or unexpected placeholder text injection
  - Verify: Inspect `WishlistItem.name` in the view model after the interaction — it must equal `""`, not nil; confirm the text field shows its placeholder text

