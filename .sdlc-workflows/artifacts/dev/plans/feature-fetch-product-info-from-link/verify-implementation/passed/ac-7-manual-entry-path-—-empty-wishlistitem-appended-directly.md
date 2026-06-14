# AC 7: Manual Entry Path — Empty WishlistItem Appended Directly

- [x] **Scenario: Selecting "Fill in manually" bypasses PasteLinkSheet and appends an empty item**
  - Given: `AddItemOptionSheet` is presented (test data namespace: `ac7-manual`)
  - When: The user taps the "Fill in manually" option
  - Then: `AddItemOptionSheet` is dismissed, no `PasteLinkSheet` is shown, and exactly one new empty `WishlistItem` is appended to `CreateWishlistViewModel.items`
  - Verify:
    - `AddItemOptionSheet`'s "manual" action calls the same append logic used by the original "Add another gift" flow, producing a `WishlistItem` with all fields at their default/empty values
    - No `PasteLinkSheet` presentation flag is set by the manual path

---

