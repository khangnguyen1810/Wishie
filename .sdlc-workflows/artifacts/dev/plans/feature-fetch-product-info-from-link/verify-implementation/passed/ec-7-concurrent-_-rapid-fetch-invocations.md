# EC 7: Concurrent / Rapid Fetch Invocations

- [x] **Scenario: User taps fetch button multiple times in rapid succession**
  - Given: `PasteLinkSheet` 'link-ec7-rapid' has a valid URL and the first fetch is already in-flight (loading state is `true`)
  - When: The user taps the fetch button again before the first request completes
  - Then: Only one active fetch executes; duplicate requests are not initiated; the loading indicator remains visible until the single in-flight request resolves
  - Verify: Confirm the view model or view disables the fetch button (or guards with an `isLoading` flag) while a request is in progress, preventing multiple concurrent `URLSession` tasks for the same action
