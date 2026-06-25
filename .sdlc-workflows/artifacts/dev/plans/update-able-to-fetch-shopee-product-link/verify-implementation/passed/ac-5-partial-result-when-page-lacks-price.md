# AC 5: Partial Result When Page Lacks Price

- [x] **Scenario: Product page with name and description but no price meta tag returns a partial result without failure**
  - Given: A product URL points to a page that renders a product `og:title` and `og:description` but contains no `product:price:amount`, `product:price:currency`, or price-related OG meta tag (scenario: `ac5-partial-no-price-product`)
  - When: The user pastes this URL into the link field and triggers fetch
  - Then: `ProductMetadataService` returns a `ProductMetadata` where `name` and `description` are populated from the page, and `price` is absent or empty — the result is surfaced as a partial success in `AddItemPasteLinkDetailSheet` rather than an error
  - Verify:
    - `ProductMetadata.name` is non-empty and reflects the page's product title
    - `ProductMetadata.description` is non-empty
    - The absence of a price does NOT cause the operation to fail or default to `"Unknown Product"`
    - No error state is shown to the user; the sheet displays the partial data and allows the item to be added
