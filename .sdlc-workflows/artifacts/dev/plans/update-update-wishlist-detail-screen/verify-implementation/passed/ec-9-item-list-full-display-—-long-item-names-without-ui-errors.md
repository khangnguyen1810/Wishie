# EC 9: Item List Full Display — Long Item Names Without UI Errors

- [x] **Scenario: Item rows with very long names and notes display fully without truncation or layout breakage**
  - Given: Wishlist `"wishlist-ec9-longtext"` has item `"item-ec9-longname"` with a name of 120 characters and a note of 300 characters; `isMostDesired = true`
  - When: The owner views the `WishlistDetailScreen` item list
  - Then: The item name is displayed completely or gracefully truncated per design spec; the star badge remains correctly positioned; no row height collapses to zero or expands beyond screen bounds
  - Verify: All text is legible; the star badge does not overlap item text; the row does not clip the image thumbnail; the list scrolls without jank
