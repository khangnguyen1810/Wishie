# Task 1: Create `WebViewMetadataExtractor` utility

- [ ] 1.1: In `Wishie/Utils/WebViewMetadataExtractor.swift` CREATE:
  - A new Swift file importing `Foundation`, `WebKit`.
  - `@MainActor final class WebViewMetadataExtractor: NSObject, WKNavigationDelegate` — a single-use extractor that loads a URL in `WKWebView` and returns `ProductMetadata`.
  - Private stored properties: `webView: WKWebView?`, `continuation: CheckedContinuation<ProductMetadata, Error>?`, `timeoutTask: Task<Void, Never>?`.
  - Public method `func extract(from url: URL) async throws -> ProductMetadata` that:
    1. Instantiates a `WKWebView` with default `WKWebViewConfiguration`.
    2. Assigns `self` as the `WKWebView`'s `navigationDelegate`.
    3. Loads the `url` via `webView.load(URLRequest(url: url))`.
    4. Wraps the operation in `withCheckedThrowingContinuation` — storing the continuation in `self.continuation`.
    5. Schedules a `timeoutTask` using `Task { try? await Task.sleep(nanoseconds: 20_000_000_000) }` that, on expiry, calls `self.finishExtraction()` to attempt partial extraction, then resumes the continuation with a `URLError(.timedOut)` if the title is still empty.
    6. Returns the `ProductMetadata` value resolved by the continuation.
  - Private method `func finishExtraction()` that:
    1. Cancels `timeoutTask`.
    2. Evaluates the extraction JavaScript string (see below) on `webView` via `webView?.evaluateJavaScript(_:completionHandler:)`.
    3. In the completion handler, parses the JavaScript result dictionary into a `ProductMetadata` value: reads keys `"title"`, `"description"`, `"image"`, `"url"`, `"price"`. `title` defaults to `"Unknown Product"` if blank.
    4. Resumes `self.continuation` with the `ProductMetadata` value (success) or with a caught error (failure).
    5. Nils out `self.continuation`, `self.webView?.navigationDelegate`, and `self.webView`.
  - `WKNavigationDelegate` method `func webView(_:didFinishNavigation:)` that:
    1. Schedules a `Task { try? await Task.sleep(nanoseconds: 2_000_000_000); await self.finishExtraction() }` to apply the 2-second post-load delay before calling `finishExtraction()`.
  - `WKNavigationDelegate` method `func webView(_:didFailProvisionalNavigation:withError:)` that resumes `self.continuation` with the error, then nils `continuation`, delegate, and `webView`.
  - `WKNavigationDelegate` method `func webView(_:didFail:withError:)` that resumes `self.continuation` with the error, then nils `continuation`, delegate, and `webView`.
  - Private computed property or constant `extractionScript: String` — a JavaScript snippet that:
    - Reads `document.querySelector('meta[property="og:title"]')?.content`, falling back to `document.title`.
    - Reads `document.querySelector('meta[property="og:image"]')?.content`.
    - Reads `document.querySelector('meta[property="og:description"]')?.content`.
    - Reads `document.querySelector('meta[property="og:url"]')?.content`, falling back to `window.location.href`.
    - Reads `document.querySelector('meta[property="product:price:amount"]')?.content` and `document.querySelector('meta[property="product:price:currency"]')?.content`; combines them as `"<currency> <amount>"` when both are present.
    - Returns a JS object `{ title, description, image, url, price }`.

