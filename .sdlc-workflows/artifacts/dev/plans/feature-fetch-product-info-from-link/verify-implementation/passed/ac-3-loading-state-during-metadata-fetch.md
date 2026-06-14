# AC 3: Loading State During Metadata Fetch

- [x] **Scenario: Submitting a product URL shows a loading indicator while fetch is in progress**
  - Given: `PasteLinkSheet` is presented and the user has entered the URL `"https://example-ac3.com/product"` (test data namespace: `ac3-loading`)
  - When: The user taps the fetch/confirm button
  - Then: A loading indicator is visible in `PasteLinkSheet` and the submit button is disabled for the duration of the asynchronous fetch
  - Verify:
    - `CreateWishlistViewModel` (or the sheet's local state) has an `isFetching: Bool` property that is set to `true` before `await` and `false` in `defer` or after completion
    - `PasteLinkSheet` renders a `ProgressView` (or equivalent) conditioned on `isFetching == true`
    - The fetch button's `.disabled` modifier is bound to `isFetching`

---

