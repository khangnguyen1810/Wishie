# EC 3: isMostDesired Data Migration — Legacy Item Lacking Field

- [x] **Scenario: Existing Firestore item without `isMostDesired` field defaults to false**
  - Given: Wishlist `"wishlist-ec3-legacy"` contains item `"item-ec3-nofield"` whose Firestore document has no `isMostDesired` key
  - When: The item is fetched and decoded into `WishlistItem`
  - Then: `isMostDesired` is `false`; no star badge appears on the item row; no decode error or crash occurs
  - Verify: The item row renders fully and correctly; the owner's bottom sheet does not pre-check "Mark as Most Desired"
