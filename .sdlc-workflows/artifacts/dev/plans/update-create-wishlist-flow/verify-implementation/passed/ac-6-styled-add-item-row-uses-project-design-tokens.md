# AC 6: Styled Add-Item Row Uses Project Design Tokens

- [x] **Scenario: Add-item row renders with project color tokens and WishieFont typography**
  - Given: `CreateWishlistPage2` is shown and the add-item row is visible
  - When: The user views the bottom of the item list
  - Then: The add-item row is visually styled using project color tokens (`.wishiePink`, `.lightYellow1`, or `.white` as defined in the design) and uses `WishieFont` typographic styles; it is not a plain `Text("+ add new item")`
  - Verify: Inspect the add-item row's foreground/background colors against the project color token definitions in `Assets.xcassets`; confirm font styling matches a `WishieFont` style rather than a system default font
