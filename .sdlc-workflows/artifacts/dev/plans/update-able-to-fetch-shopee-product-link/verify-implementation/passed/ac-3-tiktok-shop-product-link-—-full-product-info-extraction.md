# AC 3: TikTok Shop Product Link — Full Product Info Extraction

- [x] **Scenario: Pasting a TikTok Shop product URL extracts product name, description, and full price string**
  - Given: The user opens the "Add Item" sheet and the paste-link field is empty (scenario: `ac3-tiktok-shop-product-link`)
  - When: The user pastes a TikTok Shop product URL (e.g., `https://www.tiktok.com/t/...` or `https://shop.tiktok.com/...`) into the link field and triggers fetch
  - Then: `WebViewMetadataExtractor` renders the TikTok Shop product page using the default WebKit User-Agent, extracts OG meta tags and/or structured data after the 2-second delay, and returns a fully populated `ProductMetadata`
  - Verify:
    - `ProductMetadata.name` is not empty and matches the product title on TikTok Shop
    - `ProductMetadata.description` is non-empty and contains product detail text
    - `ProductMetadata.price` is non-empty and contains the full price string as it appears on TikTok Shop (e.g., "₫120.000")
    - The system does NOT invoke any URLSession-based HTML-parsing path for this URL
