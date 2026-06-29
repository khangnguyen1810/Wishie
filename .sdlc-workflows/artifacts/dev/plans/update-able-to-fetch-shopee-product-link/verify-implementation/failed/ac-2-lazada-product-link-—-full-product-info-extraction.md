# AC 2: Lazada Product Link — Full Product Info Extraction

- [x] **Scenario: Pasting a Lazada product URL extracts product name, description, and full price string** ✅ RESOLVED
  - Given: The user opens the "Add Item" sheet and the paste-link field is empty (scenario: `ac2-lazada-product-link`)
  - When: The user pastes a direct Lazada product URL (e.g., `https://www.lazada.vn/products/...`) into the link field and triggers fetch
  - Then: `ProductMetadataService` loads the URL in `WKWebView`, waits for `didFinishNavigation`, applies the 2-second post-load delay, executes the extraction JavaScript, and returns a `ProductMetadata` value with all three fields populated from the JS-rendered DOM
  - Verify:
    - `ProductMetadata.name` matches the product title on the Lazada listing page
    - `ProductMetadata.description` is non-empty and reflects product detail from the page
    - `ProductMetadata.price` is non-empty and contains the full price string including currency symbol as displayed on the Lazada page (e.g., "₫350.000")
    - The result is surfaced in `AddItemPasteLinkDetailSheet` without any change to its interface
  - **Failure**: `ProductMetadata.price` will be `nil` for Lazada product pages; the scenario requires a non-empty price string such as "₫350.000"
  - **Root Cause**: The `extractionScript` in `WebViewMetadataExtractor` reads price exclusively from two Open Graph meta tags:
    ```javascript
    var priceAmount =
      document.querySelector('meta[property="product:price:amount"]')
        ?.content || "";
    var priceCurrency =
      document.querySelector('meta[property="product:price:currency"]')
        ?.content || "";
    var price =
      priceAmount && priceCurrency ? priceCurrency + " " + priceAmount : "";
    ```
    Lazada Vietnam is a React-based SPA that renders prices in DOM elements (e.g., `span.pdp-price` or `[data-spm]` nodes). It does not expose price via `product:price:amount` or `product:price:currency` meta tags. Even after the 2-second JS-render delay, these meta tags remain absent. Consequently, both `priceAmount` and `priceCurrency` resolve to `''`, the combined `price` is `''`, and `parseMetadata` maps that to `price: nil` on `ProductMetadata`.
    A secondary format mismatch would also apply if these tags were ever present: the meta tags return ISO currency codes (e.g., "VND") combined with a raw numeric amount (e.g., "350000"), producing "VND 350000" — not the symbol-formatted string "₫350.000" displayed on the Lazada page.
    No fallback DOM-selector logic exists in the extraction script to read price from actual Lazada page elements.
  - **Affected Files**:
    - `Wishie/Utils/WebViewMetadataExtractor.swift` — `extractionScript` computed property (price extraction lines using `product:price:amount` and `product:price:currency`)
  - ✅ RESOLVED: Updated `extractionScript` in `Wishie/Utils/WebViewMetadataExtractor.swift` with a three-tier price extraction strategy:
    1. **OG meta tags** (`product:price:amount` / `product:price:currency`) — preserved as primary strategy for platforms that support it
    2. **JSON-LD structured data** — parses `script[type="application/ld+json"]` for `Product` / `Offer` schema entries, supporting both flat and `@graph`-wrapped payloads
    3. **DOM selectors** — ordered list of CSS selectors targeting Lazada-specific rendered price elements (`[class*="pdp-price"][class*="color_orange"]`, `[class*="pdp-price"][class*="size_xl"]`, etc.) and common patterns across other SPAs (TikTok Shop, Shopee fallback); returns `innerText` directly so the currency symbol and formatting (e.g., "₫350.000") are preserved exactly as displayed on the page
