# EC 4: 20-Second Timeout — Partial DOM Extraction Attempted

- [x] **Scenario: Slow page `ec4-timeout-slow` exceeds 20-second limit and surfaces timeout error**
  - Given: A product URL `ec4-timeout-slow` represents a slow-loading page where `didFinishNavigation` does not fire within 20 seconds
  - When: The `WebViewMetadataExtractor` operation timer reaches the 20-second threshold before navigation completes
  - Then: The extractor attempts a JavaScript extraction on whatever content is currently in the DOM; if the extracted title is still empty, a timeout error is returned; the `WKWebView` instance is released regardless of extraction result
  - Verify: The total operation time does not exceed approximately 20 seconds (+/- 1 second tolerance); if a title was found, a partial `ProductMetadata` is returned; if no title was found, the error is descriptive and references the timeout condition
