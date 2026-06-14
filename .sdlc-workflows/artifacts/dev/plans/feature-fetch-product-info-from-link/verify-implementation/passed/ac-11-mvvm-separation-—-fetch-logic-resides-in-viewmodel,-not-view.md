# AC 11: MVVM Separation — Fetch Logic Resides in ViewModel, Not View

- [x] **Scenario: ProductMetadataService is called from CreateWishlistViewModel, keeping views stateless coordinators**
  - Given: The source files for `CreateWishlistViewModel`, `PasteLinkSheet`, and `ProductMetadataService` (test data namespace: `ac11-mvvm`)
  - When: Code review inspects where the async fetch call is invoked
  - Then: The `URLSession`/`ProductMetadataService` call is inside `CreateWishlistViewModel`; `PasteLinkSheet` only binds to published properties and calls ViewModel methods
  - Verify:
    - `ProductMetadataService` (or its protocol) is a dependency of `CreateWishlistViewModel`, not of any View
    - `PasteLinkSheet` does not directly import or instantiate `ProductMetadataService`
    - `CreateWishlistViewModel` conforms to an `ObservableObject` and exposes `@Published` properties consumed by `PasteLinkSheet`

---

