# Verification Context — Edge Case Scenarios

## Purpose

Define testable edge case scenarios in Given/When/Then format to verify the implementation handles boundary conditions, error states, and non-functional requirements.
This document serves as the single source of truth for edge case verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "cart-ec1-empty", "user-ec2-locked"). No two scenarios should share mutable state.

## Edge Case Scenarios:

### EC 1: Short Link Redirect Resolution — Shopee

- [ ] **Scenario: Shopee short link `ec1-shp-short` resolves and extracts product metadata**
  - Given: The user has a Shopee short link `vn.shp.ee/xxxxx` (identified as `ec1-shp-short`) that redirects through multiple hops to a full Shopee product URL with JS-rendered content
  - When: `ProductMetadataService.fetchMetadata(from:)` is called with the short link `ec1-shp-short`
  - Then: `WKWebView` follows the full redirect chain to the final product URL, the 2-second post-load delay elapses, and a `ProductMetadata` value is returned containing a non-empty product name, image URL, price string, and description extracted from OG tags
  - Verify: The returned `ProductMetadata.title` is not `"Unknown Product"`, `price` is not `nil`, and the URL stored in the metadata reflects the resolved final product URL, not the short link

### EC 2: Invalid / Malformed URL Input

- [ ] **Scenario: Malformed URL string `ec2-invalid-url` causes immediate failure without crashing**
  - Given: The input string `"not-a-valid-url-ec2"` (identified as `ec2-invalid-url`) cannot be parsed into a valid `URL`
  - When: `ProductMetadataService.fetchMetadata(from:)` is called with the string `ec2-invalid-url`
  - Then: The service throws or returns a descriptive error immediately; no `WKWebView` is created and no network request is initiated
  - Verify: The error message is descriptive (e.g., indicates invalid URL); the app does not crash; `AddItemPasteLinkDetailSheet` surfaces the error state to the user

### EC 3: Network Failure During WKWebView Navigation

- [ ] **Scenario: Network error during `ec3-nav-fail` page load surfaces error without URLSession fallback**
  - Given: A `WKWebView` has begun loading a valid product URL `ec3-nav-fail` and the network connection drops mid-navigation, causing `webView(_:didFailNavigation:withError:)` to fire
  - When: The `WKNavigationDelegate` receives the navigation failure callback
  - Then: `WebViewMetadataExtractor` immediately rejects the pending continuation with a descriptive error; no URLSession fallback is attempted; the `WKWebView` instance and delegate references are cleared
  - Verify: The error propagates to `ProductMetadataService` and is surfaced to `WishlistDetailViewController`; no crash occurs; memory is released (WKWebView is nilled)

### EC 4: 20-Second Timeout — Partial DOM Extraction Attempted

- [ ] **Scenario: Slow page `ec4-timeout-slow` exceeds 20-second limit and surfaces timeout error**
  - Given: A product URL `ec4-timeout-slow` represents a slow-loading page where `didFinishNavigation` does not fire within 20 seconds
  - When: The `WebViewMetadataExtractor` operation timer reaches the 20-second threshold before navigation completes
  - Then: The extractor attempts a JavaScript extraction on whatever content is currently in the DOM; if the extracted title is still empty, a timeout error is returned; the `WKWebView` instance is released regardless of extraction result
  - Verify: The total operation time does not exceed approximately 20 seconds (+/- 1 second tolerance); if a title was found, a partial `ProductMetadata` is returned; if no title was found, the error is descriptive and references the timeout condition

### EC 5: Page with No OG Tags — Fallback to document.title

- [ ] **Scenario: Product page `ec5-no-og-tags` has no Open Graph meta tags and falls back to document title**
  - Given: A valid product URL `ec5-no-og-tags` loads in `WKWebView` and the rendered HTML contains no `og:title`, `og:image`, `og:description`, or `og:url` meta tags
  - When: The extraction JavaScript executes after the 2-second post-load delay
  - Then: `WebViewMetadataExtractor` falls back to `document.title` for the name and `window.location.href` for the URL; `image` and `price` fields are `nil`; a `ProductMetadata` with partial data is returned (not an error)
  - Verify: `ProductMetadata.title` equals the value of `document.title` from the loaded page; `ProductMetadata.imageURL` is `nil`; `ProductMetadata.price` is `nil`; no error is thrown

### EC 6: Partial Data — Price Absent, Name and Image Present

- [ ] **Scenario: Product page `ec6-no-price` has OG title and image but no price meta tag**
  - Given: A product URL `ec6-no-price` renders in `WKWebView` with `og:title` and `og:image` populated but no `product:price:amount` or equivalent price meta tag in the DOM
  - When: Extraction JavaScript executes after the 2-second post-load delay
  - Then: A `ProductMetadata` value is returned with a valid `title` and `imageURL` but with `price` set to `nil`; no error is thrown; the partial result is surfaced to the user
  - Verify: `ProductMetadata.title` is non-empty and non-`"Unknown Product"`; `ProductMetadata.imageURL` is non-nil; `ProductMetadata.price` is `nil`; `AddItemPasteLinkDetailSheet` renders the item name and image without a price field

### EC 7: Partial Data — Image Absent, Name and Price Present

- [ ] **Scenario: Product page `ec7-no-image` has OG title and price but no OG image**
  - Given: A product URL `ec7-no-image` renders in `WKWebView` with `og:title` and `product:price:amount` populated but no `og:image` meta tag in the DOM
  - When: Extraction JavaScript executes after the 2-second post-load delay
  - Then: A `ProductMetadata` value is returned with a valid `title` and `price` but with `imageURL` set to `nil`; no error is thrown; the partial result is surfaced to the user
  - Verify: `ProductMetadata.title` is non-empty; `ProductMetadata.price` is non-nil and reflects the full price string; `ProductMetadata.imageURL` is `nil`; the sheet renders without an image placeholder crash

### EC 8: Completely Empty DOM After Rendering — Defaults to "Unknown Product"

- [ ] **Scenario: Bot-detection or empty page `ec8-empty-dom` yields no extractable title**
  - Given: A URL `ec8-empty-dom` loads in `WKWebView` but the rendered page contains neither OG tags nor a meaningful `document.title` (e.g., a bot-detection wall with a blank or whitespace-only title)
  - When: Extraction JavaScript executes after the 2-second post-load delay and `document.title` is empty or whitespace
  - Then: `WebViewMetadataExtractor` defaults the `title` field to `"Unknown Product"` and returns a `ProductMetadata` with all other fields as `nil`
  - Verify: `ProductMetadata.title` equals exactly `"Unknown Product"`; no crash occurs; the result is surfaced as a partial result (not an error) to `AddItemPasteLinkDetailSheet`

### EC 9: JS Rendering Delay — Content Injected After didFinishNavigation

- [ ] **Scenario: JS-rendered content `ec9-late-js` appears only after the 2-second post-load delay**
  - Given: A product URL `ec9-late-js` (simulating a React/Vue SPA product page) fires `didFinishNavigation` with an empty HTML shell; OG meta tags are injected into the DOM approximately 1 second after `didFinishNavigation`
  - When: `WebViewMetadataExtractor` waits the mandatory 2-second post-load delay and then executes the extraction JavaScript
  - Then: The extraction JavaScript finds the now-populated OG tags and returns a complete `ProductMetadata` with title, image, description, and price
  - Verify: `ProductMetadata.title` is not `"Unknown Product"`; the 2-second delay is applied even when `didFinishNavigation` fires quickly; extraction is not performed before the 2-second delay elapses

### EC 10: WKWebView Memory Release After Extraction

- [ ] **Scenario: WKWebView instance for `ec10-mem-release` is deallocated after successful extraction**
  - Given: `WebViewMetadataExtractor.extract(from:)` is called with a valid product URL `ec10-mem-release` and completes successfully
  - When: The `async` function returns the `ProductMetadata` result
  - Then: The `WKWebView` instance is `nil`ed, the `WKNavigationDelegate` reference is cleared, and no strong reference cycle prevents deallocation
  - Verify: After the call returns, the `WebViewMetadataExtractor`'s internal `webView` property is `nil`; calling `extract(from:)` again with a different URL creates a fresh `WKWebView` instance rather than reusing the previous one

### EC 11: Lazada Short Link — Multi-Hop Redirect Chain

- [ ] **Scenario: Lazada short URL `ec11-lazada-short` follows multi-hop redirect to product page**
  - Given: A Lazada short URL `ec11-lazada-short` (e.g., `s.lazada.vn/xxxxx`) redirects through two or more HTTP hops before arriving at the full Lazada product URL with a JS-rendered page
  - When: `ProductMetadataService.fetchMetadata(from:)` is called with the Lazada short URL `ec11-lazada-short`
  - Then: `WKWebView` natively follows all redirect hops; the 2-second post-load delay allows JS to settle; a `ProductMetadata` value is returned with at minimum a non-empty title
  - Verify: The resolved metadata `title` is not `"Unknown Product"` and not empty; no per-domain detection logic is involved (the unified `WKWebView` path handles all redirects transparently)

### EC 12: TikTok Shop Link — Full Price String Preserved

- [ ] **Scenario: TikTok Shop product URL `ec12-tiktok-price` returns full price string without truncation**
  - Given: A TikTok Shop product URL `ec12-tiktok-price` renders in `WKWebView` with a price meta tag containing a full price string such as `"₫299.000"` or `"299000 VND"`
  - When: Extraction JavaScript collects `product:price:amount` and `product:price:currency` (or equivalent) meta-tag values
  - Then: `ProductMetadata.price` contains the complete price string without truncation or currency stripping; the value exactly matches what the meta tag contains
  - Verify: `ProductMetadata.price` is non-nil; the string value is not truncated; currency symbols and formatting characters are preserved as-is from the source meta tag
