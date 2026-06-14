# EC 5: WishlistItem Model Backward Compatibility

- [x] **Scenario: Existing `WishlistItem` JSON decoded without `price` field**
  - Given: A stored JSON payload 'item-ec5-legacy' for `WishlistItem` omits the `"price"` key entirely
  - When: `JSONDecoder` decodes the payload into `WishlistItem`
  - Then: Decoding succeeds without throwing; `item.price` is `nil`
  - Verify: Confirm `price` is declared as `String?` with no custom `CodingKeys` that would make it required; or confirm a custom `decode` implementation handles the missing key gracefully
