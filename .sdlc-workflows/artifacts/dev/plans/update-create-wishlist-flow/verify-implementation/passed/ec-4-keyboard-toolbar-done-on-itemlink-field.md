# EC 4: Keyboard Toolbar "Done" on itemLink Field

- [x] **Scenario: Tapping Done while itemLink field is focused dismisses the keyboard**
  - Given: WishlistItemCard 'item-ec4-linkfocus' has its `itemLink` text field focused (not `name` or `description`)
  - When: The user taps the "Done" button on the keyboard toolbar
  - Then: `focusedField` is set to `nil`, the keyboard dismisses, and no other field on the card gains focus
  - Verify: After tapping Done, confirm no text field retains first responder status on 'item-ec4-linkfocus'

