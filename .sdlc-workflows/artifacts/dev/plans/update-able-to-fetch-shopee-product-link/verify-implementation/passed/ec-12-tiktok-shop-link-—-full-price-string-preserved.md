# EC 12: TikTok Shop Link — Full Price String Preserved

- [x] **Scenario: TikTok Shop product URL `ec12-tiktok-price` returns full price string without truncation**
  - Given: A TikTok Shop product URL `ec12-tiktok-price` renders in `WKWebView` with a price meta tag containing a full price string such as `"₫299.000"` or `"299000 VND"`
  - When: Extraction JavaScript collects `product:price:amount` and `product:price:currency` (or equivalent) meta-tag values
  - Then: `ProductMetadata.price` contains the complete price string without truncation or currency stripping; the value exactly matches what the meta tag contains
  - Verify: `ProductMetadata.price` is non-nil; the string value is not truncated; currency symbols and formatting characters are preserved as-is from the source meta tag
