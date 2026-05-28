# AC 4: Three Input Fields Without Price

- [x] **Scenario: WishlistItemCard exposes exactly name, description, and itemLink fields**
  - Given: `CreateWishlistPage2` is shown with a `WishlistItem` named "item-ac4-fields"
  - When: The user inspects the visible input fields inside `WishlistItemCard`
  - Then: Exactly three text input fields are present (name, description, itemLink), each bound to the corresponding property of `WishlistItem`; no price field is rendered anywhere on the card
  - Verify: Interact with each field and confirm values flow into `WishlistItem.name`, `WishlistItem.description`, and `WishlistItem.itemLink` respectively; confirm the `WishlistItem` model's price property (if it exists) is never displayed or mutated by this screen

