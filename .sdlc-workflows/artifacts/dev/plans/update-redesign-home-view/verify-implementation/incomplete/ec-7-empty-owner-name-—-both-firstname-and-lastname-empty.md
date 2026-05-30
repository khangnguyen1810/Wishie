# EC 7: Empty Owner Name — Both firstName and lastName Empty

- [x] **Scenario: Wishlist card gracefully handles a UserModel with both name fields empty**
  - Given: A `UserModel` ('user-ec7-empty-name') has `firstName = ""` and `lastName = ""`
  - When: `HomeItemViewCell` renders the owner row `Text("\(item.1.firstName) \(item.1.lastName)")`
  - Then: The owner name `Text` renders an empty string (or a single space) without UI overflow; the owner avatar circle (`ZStack` with `Circle`) remains visible and correctly sized at 28×28 pt
  - Verify: No layout shift or hidden-view clipping occurs; the owner row `HStack` does not collapse unexpectedly
