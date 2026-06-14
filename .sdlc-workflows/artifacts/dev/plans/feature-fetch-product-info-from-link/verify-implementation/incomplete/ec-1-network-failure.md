# EC 1: Network Failure

- [x] **Scenario: Fetch fails due to unreachable host**
  - Given: `PasteLinkSheet` 'link-ec1-unreachable' has URL `"https://unreachable.invalid/product"` entered
  - When: The user taps the fetch/confirm button and `URLSession` throws a connection error (e.g., `NSURLErrorCannotFindHost`)
  - Then: `PasteLinkSheet` hides the loading indicator and displays a human-readable error message; no `WishlistItem` is appended to `CreateWishlistViewModel.items`
  - Verify: In `ProductMetadataService` (or `CreateWishlistViewModel`), confirm the `catch` block maps `URLError` to a user-facing string and that the view model's `items` array is not mutated on error

- [x] **Scenario: Fetch request times out**
  - Given: `PasteLinkSheet` 'link-ec1-timeout' has a valid URL entered and the server never responds within the configured timeout
  - When: `URLSession` raises `URLError.timedOut`
  - Then: The loading indicator is dismissed and an error message is shown; no partial `WishlistItem` is created
  - Verify: Confirm `URLSessionConfiguration` sets a finite `timeoutIntervalForRequest`; confirm error is surfaced to the view rather than silently swallowed
