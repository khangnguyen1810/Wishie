# EC 2: Extreme Aspect Ratio Image — Landscape

- [x] **Scenario: Wide landscape image with 16:3 aspect ratio renders without vertical overflow**
  - Given: WishlistItemCard 'item-ec2-landscape' has a very wide landscape image (16:3 aspect ratio) selected as its photo
  - When: The card renders inside the item list
  - Then: The image fills the fixed frame respecting `minHeight: 180`, is clipped to `RoundedRectangle(cornerRadius: 12, style: .continuous)`, and does not collapse to zero height or produce a layout break
  - Verify: Measure the rendered image area height; confirm it is at least 180pt and the card height is stable across re-renders

