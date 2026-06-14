# AC 5: Fetch Failure — Human-Readable Error Message

- [x] **Scenario: A failed fetch surfaces a human-readable error message in PasteLinkSheet**
  - Given: `PasteLinkSheet` initiates a fetch for URL `"https://fail-ac5.example.com/product"` and `ProductMetadataService` throws a network or parsing error (test data namespace: `ac5-error`)
  - When: The fetch completes with an error
  - Then: `PasteLinkSheet` displays a human-readable error string (not a raw system error code), the loading indicator is hidden, and no metadata preview is shown
  - Verify:
    - `CreateWishlistViewModel` (or the sheet) has a `fetchError: String?` property set to a user-facing message on failure
    - `PasteLinkSheet` renders the error message text conditionally on `fetchError != nil`
    - No `ProductMetadata` preview UI is rendered when an error is present

---
