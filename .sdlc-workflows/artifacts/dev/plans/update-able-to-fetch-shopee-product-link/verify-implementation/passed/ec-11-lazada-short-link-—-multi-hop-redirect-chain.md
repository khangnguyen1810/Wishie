# EC 11: Lazada Short Link — Multi-Hop Redirect Chain

- [x] **Scenario: Lazada short URL `ec11-lazada-short` follows multi-hop redirect to product page**
  - Given: A Lazada short URL `ec11-lazada-short` (e.g., `s.lazada.vn/xxxxx`) redirects through two or more HTTP hops before arriving at the full Lazada product URL with a JS-rendered page
  - When: `ProductMetadataService.fetchMetadata(from:)` is called with the Lazada short URL `ec11-lazada-short`
  - Then: `WKWebView` natively follows all redirect hops; the 2-second post-load delay allows JS to settle; a `ProductMetadata` value is returned with at minimum a non-empty title
  - Verify: The resolved metadata `title` is not `"Unknown Product"` and not empty; no per-domain detection logic is involved (the unified `WKWebView` path handles all redirects transparently)
