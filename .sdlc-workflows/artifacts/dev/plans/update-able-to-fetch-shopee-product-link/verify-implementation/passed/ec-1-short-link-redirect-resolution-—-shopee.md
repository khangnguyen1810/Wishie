# EC 1: Short Link Redirect Resolution — Shopee

- [x] **Scenario: Shopee short link `ec1-shp-short` resolves and extracts product metadata**
  - Given: The user has a Shopee short link `vn.shp.ee/xxxxx` (identified as `ec1-shp-short`) that redirects through multiple hops to a full Shopee product URL with JS-rendered content
  - When: `ProductMetadataService.fetchMetadata(from:)` is called with the short link `ec1-shp-short`
  - Then: `WKWebView` follows the full redirect chain to the final product URL, the 2-second post-load delay elapses, and a `ProductMetadata` value is returned containing a non-empty product name, image URL, price string, and description extracted from OG tags
  - Verify: The returned `ProductMetadata.title` is not `"Unknown Product"`, `price` is not `nil`, and the URL stored in the metadata reflects the resolved final product URL, not the short link
