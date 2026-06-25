# EC 2: Invalid / Malformed URL Input

- [x] **Scenario: Malformed URL string `ec2-invalid-url` causes immediate failure without crashing** ✅ RESOLVED
  - Given: The input string `"not-a-valid-url-ec2"` (identified as `ec2-invalid-url`) cannot be parsed into a valid `URL`
  - When: `ProductMetadataService.fetchMetadata(from:)` is called with the string `ec2-invalid-url`
  - Then: The service throws or returns a descriptive error immediately; no `WKWebView` is created and no network request is initiated
  - Verify: The error message is descriptive (e.g., indicates invalid URL); the app does not crash; `AddItemPasteLinkDetailSheet` surfaces the error state to the user
  - **Failure**: `URL(string: "not-a-valid-url-ec2")` returns a **non-nil** relative URL in Swift/Foundation (RFC 3986 allows scheme-less strings as relative URL references). The `guard let url = URL(string: urlString)` check does NOT fire, so `URLError(.badURL)` is never thrown immediately. Instead, `WebViewMetadataExtractor().extract(from:)` is called, which creates a `WKWebView`, adds it to the key window, and calls `webView.load(URLRequest(url: url))` — initiating a network request. The navigation then fails with an NSURLError (unsupported URL / no scheme) from `didFailProvisionalNavigation`, surfacing a non-descriptive system error rather than `URLError(.badURL)`.
  - **Root Cause**: The URL validation in `ProductMetadataService` only checks `URL(string:) != nil`, which is insufficient. A string like `"not-a-valid-url-ec2"` passes this check as a valid relative URL reference. Robust validation requires also verifying that the URL has an absolute, supported scheme (e.g., `url.scheme == "https" || url.scheme == "http"`).
  - **Fix Applied**: Added a second `guard` in `ProductMetadataService.fetchMetadata(from:)` after the existing `URL(string:)` guard: `guard url.scheme == "https" || url.scheme == "http" else { throw URLError(.badURL) }`. This ensures scheme-less strings like `"not-a-valid-url-ec2"` are rejected immediately, before any `WKWebView` is created or network request is initiated.
  - **Affected Files**:
    - `Wishie/Services/ProductMetadataService.swift` lines 12–13 — guard that should reject scheme-less or non-HTTP/HTTPS URLs but does not
    - `Wishie/Utils/WebViewMetadataExtractor.swift` lines 17–29 — `WKWebView` creation and `webView.load(_:)` that are reached despite the input being semantically invalid
