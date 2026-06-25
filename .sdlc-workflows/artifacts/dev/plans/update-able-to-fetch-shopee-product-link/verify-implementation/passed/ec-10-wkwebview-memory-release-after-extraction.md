# EC 10: WKWebView Memory Release After Extraction

- [x] **Scenario: WKWebView instance for `ec10-mem-release` is deallocated after successful extraction**
  - Given: `WebViewMetadataExtractor.extract(from:)` is called with a valid product URL `ec10-mem-release` and completes successfully
  - When: The `async` function returns the `ProductMetadata` result
  - Then: The `WKWebView` instance is `nil`ed, the `WKNavigationDelegate` reference is cleared, and no strong reference cycle prevents deallocation
  - Verify: After the call returns, the `WebViewMetadataExtractor`'s internal `webView` property is `nil`; calling `extract(from:)` again with a different URL creates a fresh `WKWebView` instance rather than reusing the previous one
