# EC 8: Malformed or Non-HTML Response

- [x] **Scenario: Server returns a non-HTML content type (e.g., JSON or binary)**
  - Given: `ProductMetadataService` 'meta-ec8-nohtml' receives a 200 response with `Content-Type: application/json` and a JSON body instead of HTML
  - When: The parser attempts to extract Open Graph tags
  - Then: No metadata is extracted; the service returns a failure or empty result; the user sees an error or empty preview — no crash occurs
  - Verify: Confirm the HTML parser handles non-HTML strings gracefully (e.g., regex finds no matches and returns `nil` fields rather than throwing); confirm no force-unwrap on parse results
