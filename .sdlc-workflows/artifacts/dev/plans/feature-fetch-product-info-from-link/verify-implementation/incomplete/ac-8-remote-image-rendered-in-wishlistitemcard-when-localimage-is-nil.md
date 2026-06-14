# AC 8: Remote Image Rendered in WishlistItemCard When localImage Is Nil

- [x] **Scenario: WishlistItemCard displays the remote image URL via WishieWebImage when localImage is nil**
  - Given: A `WishlistItem` with `localImage == nil` and `image == "https://img.example-ac8.com/thumb.jpg"` is rendered inside `WishlistItemCard` (test data namespace: `ac8-remote-image`)
  - When: `WishlistItemCard` computes its image view
  - Then: `WishieWebImage` is rendered using `item.image` as its URL source; no placeholder for `localImage` is shown
  - Verify:
    - `WishlistItemCard` has a conditional branch: `if let localImage = item.localImage { Image(uiImage:) } else { WishieWebImage(url: item.image) }`
    - `WishieWebImage` receives the non-nil `item.image` string/URL in the `else` branch

---
