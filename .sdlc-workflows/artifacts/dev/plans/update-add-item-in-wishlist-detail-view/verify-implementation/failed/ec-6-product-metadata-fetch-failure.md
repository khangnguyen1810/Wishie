# EC 6: Product Metadata Fetch Failure

- [x] **Scenario: Metadata fetch error is surfaced in paste-link sheet without blocking dismissal** ✅ RESOLVED
  - Given: `AddItemPasteLinkDetailSheet` is presented with a URL input of `"https://invalid-ec6.example.com"`
  - When: `ProductMetadataService` fetch call fails (network error or non-parseable response)
  - Then: `metadataFetchError` is set with an error message visible in the sheet; the "Add to wishlist" confirm action remains unavailable until valid metadata is fetched
  - Verify: Confirm `metadataFetchError` binding is set on fetch failure and the confirm button is disabled while `metadataFetchError` is non-nil or metadata is absent
  - **Resolution**:
    - **Root Cause 1 Fixed**: Updated `WishieButton` `enabled` condition in `AddItemPasteLinkDetailSheet.swift` to `!viewModel.newItemName.trimmingCharacters(in: .whitespaces).isEmpty && viewModel.metadataFetchError == nil`. The confirm button is now disabled whenever an active fetch error exists.
    - **Root Cause 2 Fixed**: Updated `fetchProductMetadataForNewItem(from:)` catch block in `WishlistDetailViewController.swift` to clear `newItemName`, `newItemDescription`, and `newItemRemoteImageUrl` on failure. Stale metadata from a prior successful fetch is no longer retained when the current fetch errors.
  - **Affected Files**:
    - `Wishie/Screens/Detail/AddItemPasteLinkDetailSheet.swift` — `WishieButton` `enabled` condition updated
    - `Wishie/Screens/Detail/WishlistDetailViewController.swift` — catch block now resets metadata fields on failure

---
