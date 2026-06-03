# EC 1: Gradient Theme Fallback — Invalid themeColor String

- [ ] **Scenario: Wishlist with unrecognized themeColor renders sunset fallback gradient**
  - Given: A `WishlistModel` ('wishlist-ec1-invalid-theme') has `themeColor` set to the unrecognized string `"rainbow"` which does not match any `GradientTheme` raw value
  - When: `HomeItemViewCell` renders this wishlist's card background using `item.0.theme`
  - Then: The card background displays the `.sunset` fallback gradient (primary `#FEF3D7` → secondary `#F1D790`) with no crash or transparent fill
  - Verify: Confirm `GradientTheme(rawValue: "rainbow") ?? .sunset` resolves to `.sunset`; the card visually shows the warm yellow gradient

