# EC 5: Page with No OG Tags — Fallback to document.title

- [x] **Scenario: Product page `ec5-no-og-tags` has no Open Graph meta tags and falls back to document title**
  - Given: A valid product URL `ec5-no-og-tags` loads in `WKWebView` and the rendered HTML contains no `og:title`, `og:image`, `og:description`, or `og:url` meta tags
  - When: The extraction JavaScript executes after the 2-second post-load delay
  - Then: `WebViewMetadataExtractor` falls back to `document.title` for the name and `window.location.href` for the URL; `image` and `price` fields are `nil`; a `ProductMetadata` with partial data is returned (not an error)
  - Verify: `ProductMetadata.title` equals the value of `document.title` from the loaded page; `ProductMetadata.imageURL` is `nil`; `ProductMetadata.price` is `nil`; no error is thrown
