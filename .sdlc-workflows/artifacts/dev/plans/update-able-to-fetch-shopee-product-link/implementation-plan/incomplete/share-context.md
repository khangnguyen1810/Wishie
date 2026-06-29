# Share Context

## Important Instructions for Implementation

- `WKWebView` creation, all navigation loading, delegate callbacks, and `evaluateJavaScript` MUST execute on the main actor. `WebViewMetadataExtractor` MUST be marked `@MainActor`.
- `ProductMetadataService.fetchMetadata(from:)` is NOT `@MainActor`; it MUST invoke `WebViewMetadataExtractor.extract(from:)` inside `await MainActor.run {}`.
- Create a fresh `WKWebView` instance per call and nil all references (delegate, `WKWebView` itself, continuation) immediately after extraction to prevent memory leaks.
- Apply a 2-second post-load delay after `webView(_:didFinishNavigation:)` fires before executing JavaScript, to allow JS-rendered content to settle.
- Apply a 20-second total operation timeout; on expiry, attempt extraction of whatever DOM state is available, then throw if `title` is still empty.
- `ProductMetadataServiceProtocol`, `ProductMetadata`, `WishlistDetailViewController`, and all view files MUST NOT be modified.
- No third-party dependencies. Only `WebKit` (system framework) is added as an import.
- No code comments, no debug logging, no TODO statements.

## Reused Existing Functions/Utilities

- `ProductMetadataServiceProtocol.fetchMetadata(from:)`: Existing protocol contract in `Wishie/Services/ProductMetadataService.swift` that MUST remain unchanged.
- `ProductMetadata`: Existing value type in `Wishie/Models/ProductMetadata.swift` used as the return type for extracted metadata.

## Shared Contracts

### Entities

- `ProductMetadata`: Value type in `Wishie/Models/ProductMetadata.swift`. Fields: `title: String`, `productDescription: String`, `imageUrl: String?`, `productUrl: String`, `price: String?`. `title` defaults to `"Unknown Product"` when empty. Partial results (missing image or price) are valid.

### Interfaces

- `ProductMetadataServiceProtocol`: Protocol in `Wishie/Services/ProductMetadataService.swift`. Single method: `func fetchMetadata(from urlString: String) async throws -> ProductMetadata`. MUST NOT be changed.

### DTOs

None.

