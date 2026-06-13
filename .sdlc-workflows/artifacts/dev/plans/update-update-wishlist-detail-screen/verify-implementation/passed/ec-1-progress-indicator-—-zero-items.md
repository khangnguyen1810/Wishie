# EC 1: Progress Indicator — Zero Items

- [x] **Scenario: Progress bar renders without divide-by-zero when wishlist is empty**
  - Given: Wishlist `"wishlist-ec1-empty"` exists with `0` items and an owner is viewing the detail screen
  - When: The `WishlistDetailScreen` header loads
  - Then: The progress bar displays without a crash or NaN/Inf fill value, and the label shows `"0 / 0 gifts selected"` or a safe empty-state message
  - Verify: No runtime exception is thrown; the progress bar fill remains at `0.0`; the header layout is not broken or clipped
