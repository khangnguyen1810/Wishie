# Task 2: Create ProductMetadata model and ProductMetadataService

- [ ] 2.1: In `Wishie/Models/ProductMetadata.swift` CREATE:
  - Define `struct ProductMetadata` with fields: `title: String`, `productDescription: String`, `imageUrl: String?`, `productUrl: String`, `price: String?`.
  - No `Codable` or `Identifiable` conformance needed.

- [ ] 2.2: In `Wishie/Services/ProductMetadataService.swift` CREATE:
  - Define `protocol ProductMetadataServiceProtocol` with method `func fetchMetadata(from urlString: String) async throws -> ProductMetadata`.
  - Define `class ProductMetadataService: ProductMetadataServiceProtocol` that implements the protocol.
  - In `fetchMetadata(from urlString:)`:
    - Validate the URL using `URL(string: urlString)` — throw `URLError(.badURL)` if nil.
    - Build a `URLRequest` with the URL, set `User-Agent` header to `"Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"`, set `timeoutInterval` to `15`.
    - Fetch data using `URLSession.shared.data(for:)` — throw on non-2xx HTTP status codes by checking `(response as? HTTPURLResponse)?.statusCode`.
    - Convert data to `String` using UTF-8 encoding (fallback `latin1`).
    - Call private helper `extractMetadata(from html: String, originalUrl: String) -> ProductMetadata` to parse the HTML.
  - In `extractMetadata(from:originalUrl:)`:
    - Use a private helper `func extractMetaContent(from html: String, property: String) -> String?` that searches for `<meta property="PROPERTY" content="VALUE">` or `<meta content="VALUE" property="PROPERTY">` patterns using `NSRegularExpression` with case-insensitive matching.
    - Use a private helper `func extractMetaName(from html: String, name: String) -> String?` that searches for `<meta name="NAME" content="VALUE">` or `<meta content="VALUE" name="NAME">` patterns.
    - Use a private helper `func extractTitleTag(from html: String) -> String?` that extracts content between `<title>` and `</title>`.
    - Resolve title: `extractMetaContent(property: "og:title")` → fallback `extractTitleTag()` → fallback `"Unknown Product"`.
    - Resolve description: `extractMetaContent(property: "og:description")` → fallback `extractMetaName(name: "description")` → fallback `""`.
    - Resolve imageUrl: `extractMetaContent(property: "og:image")`.
    - Resolve productUrl: `extractMetaContent(property: "og:url")` → fallback `originalUrl`.
    - Resolve price: attempt `extractMetaContent(property: "product:price:amount")`, then `extractMetaContent(property: "og:price:amount")`. If found and a currency is also found via `extractMetaContent(property: "product:price:currency")` or `extractMetaContent(property: "og:price:currency")`, format as `"CURRENCY AMOUNT"` (e.g., `"USD 29.99"`); otherwise use the raw amount string.
    - Return `ProductMetadata(title:productDescription:imageUrl:productUrl:price:)`.

---

