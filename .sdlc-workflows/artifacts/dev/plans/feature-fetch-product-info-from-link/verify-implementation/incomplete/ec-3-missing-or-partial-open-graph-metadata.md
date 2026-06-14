# EC 3: Missing or Partial Open Graph Metadata

- [x] **Scenario: HTML has no `og:title` — falls back to `<title>` tag**
  - Given: `ProductMetadataService` 'meta-ec3-notitle' fetches HTML that contains `<title>Fallback Page Title</title>` but no `<meta property="og:title">` tag
  - When: The HTML parser extracts metadata
  - Then: `ProductMetadata.title` equals `"Fallback Page Title"` from the `<title>` tag
  - Verify: Confirm the parser attempts `og:title` first and falls back to `<title>` when absent; both code paths produce a non-empty title

- [x] **Scenario: HTML has no `og:url` — falls back to the original request URL**
  - Given: `ProductMetadataService` 'meta-ec3-nourl' fetches HTML with no `<meta property="og:url">` tag; the original request URL is `"https://store.example.com/product/123"`
  - When: The HTML parser extracts metadata
  - Then: `ProductMetadata.url` equals `"https://store.example.com/product/123"` (the original URL)
  - Verify: Confirm the fallback assignment uses the URL passed into the fetch call when `og:url` is absent

- [x] **Scenario: HTML has no price meta tags**
  - Given: `ProductMetadataService` 'meta-ec3-noprice' fetches HTML with no `product:price:amount` or `og:price` meta tag
  - When: The HTML parser extracts metadata
  - Then: `ProductMetadata.price` is `nil`; the resulting `WishlistItem.price` is `nil`; the preview UI omits the price field gracefully without crashing
  - Verify: Confirm `price` is declared `Optional` in both `ProductMetadata` and `WishlistItem`; confirm the preview view handles `nil` price without force-unwrapping

- [x] **Scenario: HTML has no Open Graph tags at all**
  - Given: `ProductMetadataService` 'meta-ec3-noogs' fetches a plain HTML page with only a `<title>` tag and no `<meta>` tags
  - When: The parser processes the response
  - Then: `title` uses the `<title>` value, `description` is `nil`, `image` is `nil`, `price` is `nil`; the resulting `WishlistItem` is still appended on confirm and the user can edit it manually
  - Verify: Confirm all OG fields are `Optional` and no crash occurs when all are absent; confirm the confirm action still works with partial metadata
