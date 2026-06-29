# EC 7: Partial Data — Image Absent, Name and Price Present

- [x] **Scenario: Product page `ec7-no-image` has OG title and price but no OG image**
  - Given: A product URL `ec7-no-image` renders in `WKWebView` with `og:title` and `product:price:amount` populated but no `og:image` meta tag in the DOM
  - When: Extraction JavaScript executes after the 2-second post-load delay
  - Then: A `ProductMetadata` value is returned with a valid `title` and `price` but with `imageURL` set to `nil`; no error is thrown; the partial result is surfaced to the user
  - Verify: `ProductMetadata.title` is non-empty; `ProductMetadata.price` is non-nil and reflects the full price string; `ProductMetadata.imageURL` is `nil`; the sheet renders without an image placeholder crash
