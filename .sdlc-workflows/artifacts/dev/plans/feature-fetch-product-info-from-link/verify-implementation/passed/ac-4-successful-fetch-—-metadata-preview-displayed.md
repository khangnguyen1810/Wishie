# AC 4: Successful Fetch — Metadata Preview Displayed

- [x] **Scenario: A successful fetch renders a metadata preview with all available fields**
  - Given: `PasteLinkSheet` initiates a fetch for URL `"https://example-ac4.com/product"` and `ProductMetadataService` returns a `ProductMetadata` value with title `"ac4-product-title"`, description `"ac4-product-description"`, image URL `"https://img.example-ac4.com/thumb.jpg"`, and price `"99.00"` (test data namespace: `ac4-preview`)
  - When: The fetch completes successfully
  - Then: `PasteLinkSheet` shows the title, description, image thumbnail, and price from the returned `ProductMetadata`; the loading indicator is hidden; and a confirm button is enabled
  - Verify:
    - `CreateWishlistViewModel` (or the sheet) exposes a `fetchedMetadata: ProductMetadata?` property populated after a successful fetch
    - `PasteLinkSheet` has conditional view blocks that render title, description, price, and an image view bound to `fetchedMetadata`
    - The confirm/add button is visible and enabled only when `fetchedMetadata != nil`

---
