# Task 2: Replace URLSession with `WebViewMetadataExtractor` in `ProductMetadataService`

- [ ] 2.1: In `Wishie/Services/ProductMetadataService.swift` UPDATE:
  - Add `import WebKit` at the top of the file (alongside `import Foundation`).
  - Replace the entire body of `func fetchMetadata(from urlString: String) async throws -> ProductMetadata` with:
    1. Validate `urlString` into a `URL`; throw `URLError(.badURL)` if invalid.
    2. `return try await MainActor.run { try await WebViewMetadataExtractor().extract(from: url) }` — delegates all fetching, redirect resolution, JS rendering, and metadata extraction to `WebViewMetadataExtractor` from task 1.1.
  - DELETE all private helper methods that are no longer called: `nonEmpty(_:)`, `extractMetadata(from:originalUrl:)`, `extractMetaContent(from:property:)`, `extractMetaName(from:name:)`, `extractTitleTag(from:)`, `extractJsonLdPrice(from:)`, `extractPriceFromJsonLdObject(_:)`, `extractMetaPrice(from:)`. These are fully superseded by the JavaScript extraction in `WebViewMetadataExtractor`.
