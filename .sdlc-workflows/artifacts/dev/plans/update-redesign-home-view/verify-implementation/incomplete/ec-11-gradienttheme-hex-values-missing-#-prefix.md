# EC 11: GradientTheme Hex Values Missing "#" Prefix

- [ ] **Scenario: Color(hex:) renders correctly for GradientTheme values with missing "#" prefix**
  - Given: `GradientTheme.forest.secondary` returns `"91C788"` (no `#`) and `GradientTheme.purpleDream.primary` returns `"F4EEFF"` (no `#`) as defined in `GradientWishlishTheme.swift`
  - When: A wishlist with `themeColor = "forest"` or `themeColor = "purpleDream"` is rendered in `HomeItemViewCell`
  - Then: The gradient card does not render a transparent, black, or missing color for the affected stop; `Color(hex:)` either normalizes the string by stripping/adding `#` or the gradient degrades gracefully to an adjacent opaque color
  - Verify: Cards with `forest` and `purpleDream` themes are visually distinguishable and not transparent; if `Color(hex:)` requires `#`, the hex strings in `GradientWishlishTheme.swift` must be corrected to include it

