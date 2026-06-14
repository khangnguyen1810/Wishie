# AC 10: Open Graph Fallback — title Tag Used When og:title Is Absent

- [x] **Scenario: ProductMetadataService falls back to the HTML title tag when og:title is missing**
  - Given: `ProductMetadataService` receives HTML that contains `<title>ac10-page-title</title>` but no `<meta property="og:title" ...>` tag (test data namespace: `ac10-og-fallback`)
  - When: `parseMetadata(from:url:)` (or equivalent) processes the HTML
  - Then: The returned `ProductMetadata.title` equals `"ac10-page-title"`
  - Verify:
    - `ProductMetadataService` first attempts to read `og:title`; on absence it falls through to extract the content of `<title>`
    - A similar fallback for `og:url` → original request URL is also present in the parsing logic

---
