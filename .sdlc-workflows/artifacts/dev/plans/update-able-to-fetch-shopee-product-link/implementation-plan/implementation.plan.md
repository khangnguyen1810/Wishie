E-commerce Link Preview - Display Product Information Instead of Webpage

# Requirement Context

## Current State

`ProductMetadataService.fetchMetadata(from:)` uses `URLSession` with a mobile `User-Agent` to perform a single HTTP GET request, then parses the raw HTML for Open Graph meta tags (`og:title`, `og:image`, `og:description`, `og:url`) and JSON-LD structured data. `WishlistDetailViewController.fetchProductMetadataForNewItem(from:)` calls this service and surfaces the result in `AddItemPasteLinkDetailSheet`.

Shopee short links (`vn.shp.ee/xxxxx`) follow a redirect chain to a full Shopee product URL. Once redirected, the product page is a client-side rendered React application: the initial HTML response contains no meaningful OG tags or product data—all content is injected into the DOM after JavaScript executes. The current implementation therefore receives an empty or generic HTML shell and extracts no useful product metadata. Lazada, Tiki, and other popular e-commerce platforms have the same issue: they rely on JavaScript rendering to populate product details.

## Goals

1. Resolve short links from any supported e-commerce platform (e.g., `vn.shp.ee`, Lazada short URLs) by correctly following the HTTP redirect chain.
2. Extract product metadata (name, image, price, description) from JavaScript-rendered product pages across supported platforms (Shopee, Lazada, Amazon, and others) using `WKWebView`-based rendering.
3. Keep the change transparent to `WishlistDetailViewController` and `AddItemPasteLinkDetailSheet`—the existing `ProductMetadataServiceProtocol` interface must remain unchanged.
4. Replace the existing `URLSession`-based HTML-parsing path with the unified `WKWebView` approach for all URLs, eliminating the need for per-domain detection logic.

## Risk & Mitigation

- **WKWebView must run on the main thread**: `WKWebView` creation, navigation loading, and `evaluateJavaScript` must all happen on the main actor. The existing `fetchProductMetadataForNewItem` task is dispatched from a `Task {}` block in the view but does not pin itself to a specific actor. Mitigation: mark `WebViewMetadataExtractor` as `@MainActor` and wrap its invocation in `await MainActor.run {}` inside `ProductMetadataService`.
- **JS rendering time after page load**: Even after `webView(_:didFinishNavigation:)` fires, dynamic content may still be injecting OG meta tags. Mitigation: apply a fixed 2-second post-load delay before executing the extraction JavaScript.
- **Timeout / slow network**: Modern e-commerce pages can be large and slow. Mitigation: apply a 20-second total operation timeout; on expiry, attempt extraction of whatever is already in the DOM, then surface an error if the title is still empty.
- **User-Agent blocking**: Many e-commerce sites return bot-detection pages for programmatic User-Agents. `WKWebView` uses the system WebKit User-Agent by default, which mirrors a real browser request and bypasses basic bot filters.
- **App Transport Security**: All targeted e-commerce sites use HTTPS so no ATS exception is required.
- **Higher memory and CPU usage vs. URLSession**: `WKWebView` loads a full browser rendering engine. Mitigation: create the `WKWebView` instance fresh per request and nil all references immediately after extraction to allow prompt deallocation.

# Technical Specification Context

## Functional Requirements:

- System MUST replace the `URLSession`-based fetch in `ProductMetadataService` with a `WKWebView`-based approach for all product URL fetches.
- System MUST load the input URL in `WKWebView`, which natively handles HTTP redirect chains (including short-link redirects from `vn.shp.ee`, Lazada, etc.).
- System MUST wait for the `WKNavigationDelegate.webView(_:didFinishNavigation:)` callback before beginning metadata extraction.
- System MUST apply a 2-second post-load delay after `didFinishNavigation` before executing the extraction JavaScript, to allow JS-rendered content to settle.
- System MUST execute JavaScript in the loaded page to collect: `og:title`, `og:image`, `og:description`, `og:url`, `product:price:amount`, and `product:price:currency` meta-tag values, falling back to `document.title` / `window.location.href` when OG tags are absent.
- System MUST return a populated `ProductMetadata` value; if the extracted title is empty, it MUST default to `"Unknown Product"`.
- System MUST surface a descriptive error (not fall back to URLSession) if the `WKWebView` navigation fails or if the total operation exceeds 20 seconds.
- System MUST show a partial result (with whatever fields were extracted) if the title is present but image or price is absent—partial data is not treated as a failure.
- System MUST NOT modify `ProductMetadataServiceProtocol`, `ProductMetadata`, `WishlistDetailViewController`, or any view file.

## Non-Functional Requirements:

- System MUST introduce a new `WebViewMetadataExtractor` class in `Wishie/Utils/` following the project convention for platform utilities.
- System MUST mark `WebViewMetadataExtractor` as `@MainActor` to satisfy WKWebView threading requirements.
- System MUST NOT introduce third-party dependencies; only `WebKit` (system-provided on iOS) is added as an import.
- System MUST release the `WKWebView` instance and clear all delegate references after each extraction call to prevent memory leaks.
- System MUST follow the project's no-comment, no-debug-logging code standards.
