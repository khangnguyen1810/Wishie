# EC 3: Network Failure During WKWebView Navigation

- [x] **Scenario: Network error during `ec3-nav-fail` page load surfaces error without URLSession fallback**
  - Given: A `WKWebView` has begun loading a valid product URL `ec3-nav-fail` and the network connection drops mid-navigation, causing `webView(_:didFailNavigation:withError:)` to fire
  - When: The `WKNavigationDelegate` receives the navigation failure callback
  - Then: `WebViewMetadataExtractor` immediately rejects the pending continuation with a descriptive error; no URLSession fallback is attempted; the `WKWebView` instance and delegate references are cleared
  - Verify: The error propagates to `ProductMetadataService` and is surfaced to `WishlistDetailViewController`; no crash occurs; memory is released (WKWebView is nilled)
