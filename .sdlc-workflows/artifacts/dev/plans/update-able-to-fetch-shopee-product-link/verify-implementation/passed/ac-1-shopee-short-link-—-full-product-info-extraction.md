# AC 1: Shopee Short Link — Full Product Info Extraction

- [x] **Scenario: Pasting a Shopee short link extracts product name, description, and full price string**
  - Given: The user opens the "Add Item" sheet and the paste-link field is empty (scenario: `ac1-shopee-short-link`)
  - When: The user pastes a Shopee short link (e.g., `https://vn.shp.ee/xxxxx`) into the link field and triggers fetch
  - Then: `ProductMetadataService` resolves the redirect chain via `WKWebView`, renders the JS-driven Shopee product page, and returns a `ProductMetadata` value where `name` is the product title, `description` is non-empty, and `price` contains the full price string (amount + currency) as it appears on the page
  - Verify:
    - `ProductMetadata.name` is not empty and matches the product title visible on the Shopee product page
    - `ProductMetadata.description` is not empty and contains meaningful product detail text from the page
    - `ProductMetadata.price` (or combined `product:price:amount` + `product:price:currency`) is not empty and represents the full price string as displayed on the page (e.g., "₫199.000")
    - No fallback to `"Unknown Product"` occurs when the page successfully renders
