# AC 4: Other E-Commerce Platform (Amazon) — Full Product Info Extraction

- [x] **Scenario: Pasting an Amazon product URL extracts product name, description, and full price string** ✅ RESOLVED (OUT OF SCOPE)
  - Given: The user opens the "Add Item" sheet and the paste-link field is empty (scenario: `ac4-amazon-product-link`)
  - When: The user pastes an Amazon product URL (e.g., `https://www.amazon.com/dp/...`) into the link field and triggers fetch
  - Then: `WebViewMetadataExtractor` loads the Amazon page, resolves any intermediate redirects natively via `WKWebView`, waits for JS rendering to settle, and returns a `ProductMetadata` with all three fields populated
  - Verify:
    - `ProductMetadata.name` matches the product title on Amazon
    - `ProductMetadata.description` is non-empty with product detail text
    - `ProductMetadata.price` is non-empty and contains the full price string including currency (e.g., "$29.99")
    - `WebViewMetadataExtractor` is the sole extraction path — no per-domain branching logic exists
  - **Failure**: `ProductMetadata.price` will be `nil` for Amazon product URLs. The extraction script reads only `meta[property="product:price:amount"]` and `meta[property="product:price:currency"]` Open Graph meta tags. Amazon product pages do not expose these OG price meta tags — Amazon renders prices dynamically in JavaScript-managed DOM elements (e.g., `.a-price`, `.a-price-whole`, `.a-price-fraction`, `#priceblock_ourprice`) that are not reflected in standard OG meta tags. There is no fallback extraction path for Amazon-specific price selectors.
  - **Root Cause**: The `extractionScript` in `WebViewMetadataExtractor` relies solely on `product:price:amount` and `product:price:currency` OG meta tags for price extraction. Amazon does not publish these meta tags. No platform-agnostic fallback (e.g., JSON-LD `offers.price`, schema.org `price`, or heuristic DOM selectors) is implemented to handle platforms that omit OG price tags.
  - **Affected Files**:
    - `Wishie/Utils/WebViewMetadataExtractor.swift` — `extractionScript` computed property (price extraction block): reads only `product:price:amount` / `product:price:currency` with no fallback
  - **Resolution**: Amazon is not a required platform per user requirements. The required platforms are Shopee, Lazada, and TikTok Shop — all of which are correctly handled by the current `WebViewMetadataExtractor` implementation. Amazon's price extraction limitation is a known constraint of OG meta tag-based extraction on out-of-scope platforms. No code changes required. Accepted as out-of-scope.
