# Verification Context — Edge Case Scenarios

## Purpose

Define testable edge case scenarios in Given/When/Then format to verify the implementation handles boundary conditions, error states, and non-functional requirements.
This document serves as the single source of truth for edge case verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "cart-ec1-empty", "user-ec2-locked"). No two scenarios should share mutable state.

> **Note:** This is a Swift/SwiftUI iOS app. All verification is performed via **code review only** — no simulator or device testing. Each scenario's "Verify" step describes what to inspect in the source code.

---

## Edge Case Scenarios:

### EC 1: Network Failure

- [ ] **Scenario: Fetch fails due to unreachable host**
  - Given: `PasteLinkSheet` 'link-ec1-unreachable' has URL `"https://unreachable.invalid/product"` entered
  - When: The user taps the fetch/confirm button and `URLSession` throws a connection error (e.g., `NSURLErrorCannotFindHost`)
  - Then: `PasteLinkSheet` hides the loading indicator and displays a human-readable error message; no `WishlistItem` is appended to `CreateWishlistViewModel.items`
  - Verify: In `ProductMetadataService` (or `CreateWishlistViewModel`), confirm the `catch` block maps `URLError` to a user-facing string and that the view model's `items` array is not mutated on error

- [ ] **Scenario: Fetch request times out**
  - Given: `PasteLinkSheet` 'link-ec1-timeout' has a valid URL entered and the server never responds within the configured timeout
  - When: `URLSession` raises `URLError.timedOut`
  - Then: The loading indicator is dismissed and an error message is shown; no partial `WishlistItem` is created
  - Verify: Confirm `URLSessionConfiguration` sets a finite `timeoutIntervalForRequest`; confirm error is surfaced to the view rather than silently swallowed

### EC 2: Bot Detection / HTTP Error Responses

- [ ] **Scenario: Server returns 403 Forbidden (bot-blocked)**
  - Given: `ProductMetadataService` 'meta-ec2-403' receives an HTTP 403 response for URL `"https://blocked-store.example.com/item"`
  - When: `URLSession` completes with `HTTPURLResponse.statusCode == 403`
  - Then: The service throws or returns a failure result; `PasteLinkSheet` displays a human-readable error; no `WishlistItem` is added
  - Verify: Confirm the service checks `HTTPURLResponse.statusCode` and treats non-2xx codes as errors; confirm the `User-Agent` header is set to a browser-like string to minimise blocking

- [ ] **Scenario: Server returns 429 Too Many Requests**
  - Given: `ProductMetadataService` 'meta-ec2-429' receives HTTP 429
  - When: The fetch completes with status 429
  - Then: Error is propagated and surfaced as a human-readable message; the user is not left in a permanent loading state
  - Verify: Same status-code guard as EC 2 scenario 1; loading/error state transitions are handled correctly in the view model

### EC 3: Missing or Partial Open Graph Metadata

- [ ] **Scenario: HTML has no `og:title` — falls back to `<title>` tag**
  - Given: `ProductMetadataService` 'meta-ec3-notitle' fetches HTML that contains `<title>Fallback Page Title</title>` but no `<meta property="og:title">` tag
  - When: The HTML parser extracts metadata
  - Then: `ProductMetadata.title` equals `"Fallback Page Title"` from the `<title>` tag
  - Verify: Confirm the parser attempts `og:title` first and falls back to `<title>` when absent; both code paths produce a non-empty title

- [ ] **Scenario: HTML has no `og:url` — falls back to the original request URL**
  - Given: `ProductMetadataService` 'meta-ec3-nourl' fetches HTML with no `<meta property="og:url">` tag; the original request URL is `"https://store.example.com/product/123"`
  - When: The HTML parser extracts metadata
  - Then: `ProductMetadata.url` equals `"https://store.example.com/product/123"` (the original URL)
  - Verify: Confirm the fallback assignment uses the URL passed into the fetch call when `og:url` is absent

- [ ] **Scenario: HTML has no price meta tags**
  - Given: `ProductMetadataService` 'meta-ec3-noprice' fetches HTML with no `product:price:amount` or `og:price` meta tag
  - When: The HTML parser extracts metadata
  - Then: `ProductMetadata.price` is `nil`; the resulting `WishlistItem.price` is `nil`; the preview UI omits the price field gracefully without crashing
  - Verify: Confirm `price` is declared `Optional` in both `ProductMetadata` and `WishlistItem`; confirm the preview view handles `nil` price without force-unwrapping

- [ ] **Scenario: HTML has no Open Graph tags at all**
  - Given: `ProductMetadataService` 'meta-ec3-noogs' fetches a plain HTML page with only a `<title>` tag and no `<meta>` tags
  - When: The parser processes the response
  - Then: `title` uses the `<title>` value, `description` is `nil`, `image` is `nil`, `price` is `nil`; the resulting `WishlistItem` is still appended on confirm and the user can edit it manually
  - Verify: Confirm all OG fields are `Optional` and no crash occurs when all are absent; confirm the confirm action still works with partial metadata

### EC 4: Invalid User Input

- [ ] **Scenario: User submits an empty URL string**
  - Given: `PasteLinkSheet` 'link-ec4-empty' has an empty text field (zero-length string)
  - When: The user taps the fetch/confirm button
  - Then: The fetch is not initiated; a validation error or disabled button prevents submission
  - Verify: Confirm the fetch trigger is guarded by a non-empty URL check (e.g., button disabled binding or early `guard` in the action handler); `URLSession` is never called with an empty string

- [ ] **Scenario: User pastes a non-URL string**
  - Given: `PasteLinkSheet` 'link-ec4-badurl' has `"not a url at all"` in the text field
  - When: The user taps the fetch/confirm button
  - Then: `URL(string:)` returns `nil`; the fetch is rejected with a human-readable error before any network call is made
  - Verify: Confirm a `URL(string:)` guard executes before `URLSession.dataTask`; confirm the error path surfaces a message to the view

### EC 5: WishlistItem Model Backward Compatibility

- [ ] **Scenario: Existing `WishlistItem` JSON decoded without `price` field**
  - Given: A stored JSON payload 'item-ec5-legacy' for `WishlistItem` omits the `"price"` key entirely
  - When: `JSONDecoder` decodes the payload into `WishlistItem`
  - Then: Decoding succeeds without throwing; `item.price` is `nil`
  - Verify: Confirm `price` is declared as `String?` with no custom `CodingKeys` that would make it required; or confirm a custom `decode` implementation handles the missing key gracefully

### EC 6: Image Display Priority in WishlistItemCard

- [ ] **Scenario: `localImage` is nil and `item.image` contains a remote URL**
  - Given: A `WishlistItem` 'item-ec6-remoteonly' where `localImage == nil` and `image == "https://cdn.example.com/product.jpg"`
  - When: `WishlistItemCard` renders this item
  - Then: `WishieWebImage` is displayed using `item.image`; no blank or placeholder image is shown where the remote image should appear
  - Verify: Confirm the card's image rendering logic checks `localImage` first and falls back to `WishieWebImage(url: item.image)` when `localImage` is `nil`

- [ ] **Scenario: Both `localImage` and `item.image` are nil**
  - Given: A `WishlistItem` 'item-ec6-noimage' where both `localImage == nil` and `image == nil`
  - When: `WishlistItemCard` renders this item
  - Then: A placeholder or empty state is displayed; the app does not crash
  - Verify: Confirm the conditional rendering handles the double-nil case without force-unwrapping either value

### EC 7: Concurrent / Rapid Fetch Invocations

- [ ] **Scenario: User taps fetch button multiple times in rapid succession**
  - Given: `PasteLinkSheet` 'link-ec7-rapid' has a valid URL and the first fetch is already in-flight (loading state is `true`)
  - When: The user taps the fetch button again before the first request completes
  - Then: Only one active fetch executes; duplicate requests are not initiated; the loading indicator remains visible until the single in-flight request resolves
  - Verify: Confirm the view model or view disables the fetch button (or guards with an `isLoading` flag) while a request is in progress, preventing multiple concurrent `URLSession` tasks for the same action

### EC 8: Malformed or Non-HTML Response

- [ ] **Scenario: Server returns a non-HTML content type (e.g., JSON or binary)**
  - Given: `ProductMetadataService` 'meta-ec8-nohtml' receives a 200 response with `Content-Type: application/json` and a JSON body instead of HTML
  - When: The parser attempts to extract Open Graph tags
  - Then: No metadata is extracted; the service returns a failure or empty result; the user sees an error or empty preview — no crash occurs
  - Verify: Confirm the HTML parser handles non-HTML strings gracefully (e.g., regex finds no matches and returns `nil` fields rather than throwing); confirm no force-unwrap on parse results
