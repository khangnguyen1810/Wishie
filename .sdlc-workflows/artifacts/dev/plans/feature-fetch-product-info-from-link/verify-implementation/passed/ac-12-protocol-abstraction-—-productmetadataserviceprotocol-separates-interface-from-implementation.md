# AC 12: Protocol Abstraction — ProductMetadataServiceProtocol Separates Interface from Implementation

- [x] **Scenario: CreateWishlistViewModel depends on ProductMetadataServiceProtocol, not the concrete type**
  - Given: The declarations of `ProductMetadataServiceProtocol`, `ProductMetadataService`, and `CreateWishlistViewModel` (test data namespace: `ac12-protocol`)
  - When: Code review inspects the ViewModel's stored property and initialiser
  - Then: `CreateWishlistViewModel` holds a reference typed as `ProductMetadataServiceProtocol`; `ProductMetadataService` conforms to `ProductMetadataServiceProtocol`; the concrete type is injected at call-site
  - Verify:
    - `CreateWishlistViewModel` has a property declared as `private let metadataService: ProductMetadataServiceProtocol`
    - `ProductMetadataService: ProductMetadataServiceProtocol` conformance exists
    - No direct reference to `ProductMetadataService` concrete type appears inside `CreateWishlistViewModel`'s method bodies
