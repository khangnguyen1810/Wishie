# AC 6: JS-Rendered OG Tags Are Captured After Post-Load Delay

- [x] **Scenario: Metadata injected by JavaScript after page load is captured due to the 2-second post-load delay**
  - Given: A product page that injects `og:title`, `og:description`, and `og:price` meta tags into the DOM via JavaScript after `DOMContentLoaded` has fired (scenario: `ac6-js-injected-og-tags`)
  - When: `WebViewMetadataExtractor` receives `didFinishNavigation`, waits the configured 2-second delay, then executes the extraction JavaScript
  - Then: The returned `ProductMetadata` contains the JS-injected values for `name`, `description`, and `price` — not empty strings that would have been captured had extraction run immediately at `didFinishNavigation`
  - Verify:
    - `ProductMetadata.name` equals the value injected by the page's JavaScript (not an empty string)
    - `ProductMetadata.description` equals the JS-injected description
    - `ProductMetadata.price` equals the JS-injected price string
    - The 2-second delay is applied before `evaluateJavaScript` is called
