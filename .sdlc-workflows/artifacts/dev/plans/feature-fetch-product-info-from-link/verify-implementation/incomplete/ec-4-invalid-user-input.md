# EC 4: Invalid User Input

- [x] **Scenario: User submits an empty URL string**
  - Given: `PasteLinkSheet` 'link-ec4-empty' has an empty text field (zero-length string)
  - When: The user taps the fetch/confirm button
  - Then: The fetch is not initiated; a validation error or disabled button prevents submission
  - Verify: Confirm the fetch trigger is guarded by a non-empty URL check (e.g., button disabled binding or early `guard` in the action handler); `URLSession` is never called with an empty string

- [x] **Scenario: User pastes a non-URL string**
  - Given: `PasteLinkSheet` 'link-ec4-badurl' has `"not a url at all"` in the text field
  - When: The user taps the fetch/confirm button
  - Then: `URL(string:)` returns `nil`; the fetch is rejected with a human-readable error before any network call is made
  - Verify: Confirm a `URL(string:)` guard executes before `URLSession.dataTask`; confirm the error path surfaces a message to the view
