# EC 1: Extreme Aspect Ratio Image — Portrait

- [x] **Scenario: Portrait image with 3:16 aspect ratio renders within fixed frame without overflow**
  - Given: WishlistItemCard 'item-ec1-portrait' has a very tall portrait image (3:16 aspect ratio) selected as its photo
  - When: The card renders inside the item list
  - Then: The image fills the fixed frame (`maxWidth: .infinity`, `minHeight: 180`) using `.scaledToFill()`, is fully clipped by `clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))`, and does not overflow the card bounds or cause layout shifts
  - Verify: Inspect the rendered card in both light and dark mode at standard iPhone sizes; confirm no image content bleeds outside the rounded rectangle boundary

