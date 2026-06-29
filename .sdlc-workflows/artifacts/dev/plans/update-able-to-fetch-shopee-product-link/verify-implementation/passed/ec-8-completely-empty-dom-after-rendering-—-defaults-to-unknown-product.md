# EC 8: Completely Empty DOM After Rendering — Defaults to "Unknown Product"

- [x] **Scenario: Bot-detection or empty page `ec8-empty-dom` yields no extractable title**
  - Given: A URL `ec8-empty-dom` loads in `WKWebView` but the rendered page contains neither OG tags nor a meaningful `document.title` (e.g., a bot-detection wall with a blank or whitespace-only title)
  - When: Extraction JavaScript executes after the 2-second post-load delay and `document.title` is empty or whitespace
  - Then: `WebViewMetadataExtractor` defaults the `title` field to `"Unknown Product"` and returns a `ProductMetadata` with all other fields as `nil`
  - Verify: `ProductMetadata.title` equals exactly `"Unknown Product"`; no crash occurs; the result is surfaced as a partial result (not an error) to `AddItemPasteLinkDetailSheet`
