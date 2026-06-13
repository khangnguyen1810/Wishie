# AC 3: Star Badge Display on Most Desired Items

- [x] **Scenario: Star badge is visible on item rows where isMostDesired is true**
  - Given: A wishlist `wishlist-ac3-starbadge` contains three items: `item-ac3-desired` (`isMostDesired = true`), `item-ac3-plain` (`isMostDesired = false`), `item-ac3-picked` (`isMostDesired = false`, `isPicked = true`)
  - When: Any user (owner or member) views the WishlistDetail screen
  - Then: A star badge is rendered on the row for `item-ac3-desired` only
  - Verify: Star badge is absent on `item-ac3-plain` and `item-ac3-picked`; the badge does not overlap or truncate the item title or image; the layout is correct on both standard and large dynamic type sizes

- [x] **Scenario: Wishlist items are displayed fully and correctly without any UI errors**
  - Given: A wishlist `wishlist-ac3-fullrender` contains 10 items with varying combinations of `isMostDesired`, `isPicked`, long titles (>40 characters), and items with and without images
  - When: The owner navigates to the WishlistDetail screen
  - Then: All 10 items are visible in the list, each displaying its title, image placeholder or thumbnail, star badge (if applicable), and picked indicator without clipping, overlap, or misalignment
  - Verify: No item row is cut off at the list boundaries; scrolling reveals all items; the star badge, picked state indicator, and text labels co-exist without visual collision; no runtime UI warnings or layout constraint errors are produced

---
