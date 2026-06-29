# EC 6: Partial Data — Price Absent, Name and Image Present

- [x] **Scenario: Product page `ec6-no-price` has OG title and image but no price meta tag**
  - Given: A product URL `ec6-no-price` renders in `WKWebView` with `og:title` and `og:image` populated but no `product:price:amount` or equivalent price meta tag in the DOM
  - When: Extraction JavaScript executes after the 2-second post-load delay
  - Then: A `ProductMetadata` value is returned with a valid `title` and `imageURL` but with `price` set to `nil`; no error is thrown; the partial result is surfaced to the user
  - Verify: `ProductMetadata.title` is non-empty and non-`"Unknown Product"`; `ProductMetadata.imageURL` is non-nil; `ProductMetadata.price` is `nil`; `AddItemPasteLinkDetailSheet` renders the item name and image without a price field
