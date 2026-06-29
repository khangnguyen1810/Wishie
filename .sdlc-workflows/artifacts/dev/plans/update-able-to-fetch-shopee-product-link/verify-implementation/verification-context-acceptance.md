# Verification Context — Acceptance Scenarios

## Purpose

Define testable acceptance scenarios in Given/When/Then format to verify the implementation meets functional requirements and success criteria.
This document serves as the single source of truth for acceptance verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "user-ac1-login", "product-ac2-checkout"). No two scenarios should share mutable state.

## Acceptance Scenarios:

### AC 1: Shopee Short Link — Full Product Info Extraction

- [ ] **Scenario: Pasting a Shopee short link extracts product name, description, and full price string**
  - Given: The user opens the "Add Item" sheet and the paste-link field is empty (scenario: `ac1-shopee-short-link`)
  - When: The user pastes a Shopee short link (e.g., `https://vn.shp.ee/xxxxx`) into the link field and triggers fetch
  - Then: `ProductMetadataService` resolves the redirect chain via `WKWebView`, renders the JS-driven Shopee product page, and returns a `ProductMetadata` value where `name` is the product title, `description` is non-empty, and `price` contains the full price string (amount + currency) as it appears on the page
  - Verify:
    - `ProductMetadata.name` is not empty and matches the product title visible on the Shopee product page
    - `ProductMetadata.description` is not empty and contains meaningful product detail text from the page
    - `ProductMetadata.price` (or combined `product:price:amount` + `product:price:currency`) is not empty and represents the full price string as displayed on the page (e.g., "₫199.000")
    - No fallback to `"Unknown Product"` occurs when the page successfully renders

### AC 2: Lazada Product Link — Full Product Info Extraction

- [ ] **Scenario: Pasting a Lazada product URL extracts product name, description, and full price string**
  - Given: The user opens the "Add Item" sheet and the paste-link field is empty (scenario: `ac2-lazada-product-link`)
  - When: The user pastes a direct Lazada product URL (e.g., `https://www.lazada.vn/products/...`) into the link field and triggers fetch
  - Then: `ProductMetadataService` loads the URL in `WKWebView`, waits for `didFinishNavigation`, applies the 2-second post-load delay, executes the extraction JavaScript, and returns a `ProductMetadata` value with all three fields populated from the JS-rendered DOM
  - Verify:
    - `ProductMetadata.name` matches the product title on the Lazada listing page
    - `ProductMetadata.description` is non-empty and reflects product detail from the page
    - `ProductMetadata.price` is non-empty and contains the full price string including currency symbol as displayed on the Lazada page (e.g., "₫350.000")
    - The result is surfaced in `AddItemPasteLinkDetailSheet` without any change to its interface

### AC 3: TikTok Shop Product Link — Full Product Info Extraction

- [ ] **Scenario: Pasting a TikTok Shop product URL extracts product name, description, and full price string**
  - Given: The user opens the "Add Item" sheet and the paste-link field is empty (scenario: `ac3-tiktok-shop-product-link`)
  - When: The user pastes a TikTok Shop product URL (e.g., `https://www.tiktok.com/t/...` or `https://shop.tiktok.com/...`) into the link field and triggers fetch
  - Then: `WebViewMetadataExtractor` renders the TikTok Shop product page using the default WebKit User-Agent, extracts OG meta tags and/or structured data after the 2-second delay, and returns a fully populated `ProductMetadata`
  - Verify:
    - `ProductMetadata.name` is not empty and matches the product title on TikTok Shop
    - `ProductMetadata.description` is non-empty and contains product detail text
    - `ProductMetadata.price` is non-empty and contains the full price string as it appears on TikTok Shop (e.g., "₫120.000")
    - The system does NOT invoke any URLSession-based HTML-parsing path for this URL

### AC 4: Other E-Commerce Platform (Amazon) — Full Product Info Extraction

- [ ] **Scenario: Pasting an Amazon product URL extracts product name, description, and full price string**
  - Given: The user opens the "Add Item" sheet and the paste-link field is empty (scenario: `ac4-amazon-product-link`)
  - When: The user pastes an Amazon product URL (e.g., `https://www.amazon.com/dp/...`) into the link field and triggers fetch
  - Then: `WebViewMetadataExtractor` loads the Amazon page, resolves any intermediate redirects natively via `WKWebView`, waits for JS rendering to settle, and returns a `ProductMetadata` with all three fields populated
  - Verify:
    - `ProductMetadata.name` matches the product title on Amazon
    - `ProductMetadata.description` is non-empty with product detail text
    - `ProductMetadata.price` is non-empty and contains the full price string including currency (e.g., "$29.99")
    - `WebViewMetadataExtractor` is the sole extraction path — no per-domain branching logic exists

### AC 5: Partial Result When Page Lacks Price

- [ ] **Scenario: Product page with name and description but no price meta tag returns a partial result without failure**
  - Given: A product URL points to a page that renders a product `og:title` and `og:description` but contains no `product:price:amount`, `product:price:currency`, or price-related OG meta tag (scenario: `ac5-partial-no-price-product`)
  - When: The user pastes this URL into the link field and triggers fetch
  - Then: `ProductMetadataService` returns a `ProductMetadata` where `name` and `description` are populated from the page, and `price` is absent or empty — the result is surfaced as a partial success in `AddItemPasteLinkDetailSheet` rather than an error
  - Verify:
    - `ProductMetadata.name` is non-empty and reflects the page's product title
    - `ProductMetadata.description` is non-empty
    - The absence of a price does NOT cause the operation to fail or default to `"Unknown Product"`
    - No error state is shown to the user; the sheet displays the partial data and allows the item to be added

### AC 6: JS-Rendered OG Tags Are Captured After Post-Load Delay

- [ ] **Scenario: Metadata injected by JavaScript after page load is captured due to the 2-second post-load delay**
  - Given: A product page that injects `og:title`, `og:description`, and `og:price` meta tags into the DOM via JavaScript after `DOMContentLoaded` has fired (scenario: `ac6-js-injected-og-tags`)
  - When: `WebViewMetadataExtractor` receives `didFinishNavigation`, waits the configured 2-second delay, then executes the extraction JavaScript
  - Then: The returned `ProductMetadata` contains the JS-injected values for `name`, `description`, and `price` — not empty strings that would have been captured had extraction run immediately at `didFinishNavigation`
  - Verify:
    - `ProductMetadata.name` equals the value injected by the page's JavaScript (not an empty string)
    - `ProductMetadata.description` equals the JS-injected description
    - `ProductMetadata.price` equals the JS-injected price string
    - The 2-second delay is applied before `evaluateJavaScript` is called

### AC 7: ProductMetadataServiceProtocol Interface Remains Unchanged

- [ ] **Scenario: Existing callers of ProductMetadataServiceProtocol require zero changes after the WKWebView migration**
  - Given: `WishlistDetailViewController` and `AddItemPasteLinkDetailSheet` call `ProductMetadataServiceProtocol.fetchMetadata(from:)` with a product URL (scenario: `ac7-protocol-interface-unchanged`)
  - When: The app is built and the fetch is invoked through the existing call site
  - Then: The call compiles and executes without any modification to `ProductMetadataServiceProtocol`, `WishlistDetailViewController`, or any view file — only `ProductMetadataService`'s internal implementation changed
  - Verify:
    - `ProductMetadataServiceProtocol` method signatures are identical to pre-implementation versions
    - No view file (`WishlistDetailViewController`, `AddItemPasteLinkDetailSheet`, or others) has been modified
    - The project builds without errors or warnings introduced by the migration
