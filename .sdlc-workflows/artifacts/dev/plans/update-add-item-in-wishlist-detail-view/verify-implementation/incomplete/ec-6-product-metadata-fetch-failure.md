# EC 6: Product Metadata Fetch Failure

- [ ] **Scenario: Metadata fetch error is surfaced in paste-link sheet without blocking dismissal** ❌ FAILED
  - Given: `AddItemPasteLinkDetailSheet` is presented with a URL input of `"https://invalid-ec6.example.com"`
  - When: `ProductMetadataService` fetch call fails (network error or non-parseable response)
  - Then: `metadataFetchError` is set with an error message visible in the sheet; the "Add to wishlist" confirm action remains unavailable until valid metadata is fetched
  - Verify: Confirm `metadataFetchError` binding is set on fetch failure and the confirm button is disabled while `metadataFetchError` is non-nil or metadata is absent
  - **Failure**: The confirm button is enabled based solely on `!viewModel.newItemName.trimmingCharacters(in: .whitespaces).isEmpty`. It does not include `viewModel.metadataFetchError == nil` in its enabled condition. If the user previously fetched metadata successfully (populating `newItemName`) and then retries with a failing URL, `metadataFetchError` becomes non-nil while `newItemName` remains non-empty — leaving the confirm button enabled despite an active fetch error.
  - **Root Cause 1**: `AddItemPasteLinkDetailSheet` — `WishieButton` `enabled` parameter does not gate on `metadataFetchError == nil`. Required condition: `!viewModel.newItemName.trimmingCharacters(in: .whitespaces).isEmpty && viewModel.metadataFetchError == nil`.
  - **Root Cause 2**: `WishlistDetailViewController.fetchProductMetadataForNewItem` — on fetch failure, previous metadata fields (`newItemName`, `newItemDescription`, `newItemRemoteImageUrl`) are not cleared. Stale metadata from a prior successful fetch remains, causing the confirm button to stay enabled even when the current fetch errored.
  - **Affected Files**:
    - `Wishie/Screens/Detail/AddItemPasteLinkDetailSheet.swift` — `WishieButton(title: "Add to wishlist", enabled: !viewModel.newItemName.trimmingCharacters(in: .whitespaces).isEmpty)` (line 98)
    - `Wishie/Screens/Detail/WishlistDetailViewController.swift` — `fetchProductMetadataForNewItem(from:)` catch block (line 271–273); no reset of `newItemName`, `newItemDescription`, `newItemRemoteImageUrl` on failure

---
