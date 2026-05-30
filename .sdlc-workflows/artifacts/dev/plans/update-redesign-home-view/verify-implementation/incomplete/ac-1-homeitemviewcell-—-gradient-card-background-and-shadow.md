# AC 1: HomeItemViewCell — Gradient Card Background and Shadow

- [x] **Scenario: Wishlist card renders gradient background from theme colors**
  - Given: a `WishlistModel` named `"wishlist-ac1-gradient"` with `theme.primary = "#FFD6E0"` and `theme.secondary = "#FFF0F5"`, paired with an owner `UserModel`
  - When: `HomeItemViewCell` renders with this model
  - Then: the card background displays a `LinearGradient` transitioning from `Color(hex: "#FFD6E0")` at the top to `Color(hex: "#FFF0F5")` at the bottom on a `RoundedRectangle(cornerRadius: 16)`
  - Verify: no flat `.sunset.opacity(0.5)` fill is visible; gradient fills the entire card area; `cornerRadius` is 16

- [x] **Scenario: Wishlist card displays themed shadow derived from secondary color**
  - Given: a `WishlistModel` named `"wishlist-ac1-shadow"` with `theme.secondary = "#C9B8FF"`
  - When: `HomeItemViewCell` renders with this model
  - Then: the card container has a shadow with color `Color(hex: "#C9B8FF").opacity(0.4)`, `radius: 8`, and `offset y: 4`
  - Verify: shadow is visible below the card; shadow color matches the secondary theme hex value at 40% opacity
