# AC 9: WishlistItem Model — Optional price Field and Backward Compatibility

- [x] **Scenario: WishlistItem declares an optional price field and existing instances without price remain valid**
  - Given: The `WishlistItem` model definition (test data namespace: `ac9-model`)
  - When: A `WishlistItem` is instantiated without supplying a `price` argument
  - Then: The instance compiles successfully and `item.price` equals `nil`
  - Verify:
    - `WishlistItem` declares `var price: String?` (or `let price: String?`) with a default value of `nil`
    - Any `Codable` conformance uses `decodeIfPresent` (or equivalent) so that persisted items lacking the `price` key decode without error

---

