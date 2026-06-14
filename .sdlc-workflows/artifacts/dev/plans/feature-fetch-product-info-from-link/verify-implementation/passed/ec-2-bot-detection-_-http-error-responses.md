# EC 2: Bot Detection / HTTP Error Responses

- [x] **Scenario: Server returns 403 Forbidden (bot-blocked)**
  - Given: `ProductMetadataService` 'meta-ec2-403' receives an HTTP 403 response for URL `"https://blocked-store.example.com/item"`
  - When: `URLSession` completes with `HTTPURLResponse.statusCode == 403`
  - Then: The service throws or returns a failure result; `PasteLinkSheet` displays a human-readable error; no `WishlistItem` is added
  - Verify: Confirm the service checks `HTTPURLResponse.statusCode` and treats non-2xx codes as errors; confirm the `User-Agent` header is set to a browser-like string to minimise blocking

- [x] **Scenario: Server returns 429 Too Many Requests**
  - Given: `ProductMetadataService` 'meta-ec2-429' receives HTTP 429
  - When: The fetch completes with status 429
  - Then: Error is propagated and surfaced as a human-readable message; the user is not left in a permanent loading state
  - Verify: Same status-code guard as EC 2 scenario 1; loading/error state transitions are handled correctly in the view model

