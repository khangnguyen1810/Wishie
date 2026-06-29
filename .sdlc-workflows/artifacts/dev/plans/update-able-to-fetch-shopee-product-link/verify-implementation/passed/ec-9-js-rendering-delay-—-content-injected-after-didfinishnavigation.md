# EC 9: JS Rendering Delay — Content Injected After didFinishNavigation

- [x] **Scenario: JS-rendered content `ec9-late-js` appears only after the 2-second post-load delay**
  - Given: A product URL `ec9-late-js` (simulating a React/Vue SPA product page) fires `didFinishNavigation` with an empty HTML shell; OG meta tags are injected into the DOM approximately 1 second after `didFinishNavigation`
  - When: `WebViewMetadataExtractor` waits the mandatory 2-second post-load delay and then executes the extraction JavaScript
  - Then: The extraction JavaScript finds the now-populated OG tags and returns a complete `ProductMetadata` with title, image, description, and price
  - Verify: `ProductMetadata.title` is not `"Unknown Product"`; the 2-second delay is applied even when `didFinishNavigation` fires quickly; extraction is not performed before the 2-second delay elapses
