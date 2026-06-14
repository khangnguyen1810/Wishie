# Verification Context — Acceptance Scenarios

## Purpose

Define testable acceptance scenarios in Given/When/Then format to verify the implementation meets functional requirements and success criteria.
This document serves as the single source of truth for acceptance verification.

> **Scope note:** This is a Swift/SwiftUI iOS app. All verification is performed via code review only — no simulator or device testing. "Then" clauses describe code-level evidence that the behaviour is correctly implemented.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "user-ac1-login", "product-ac2-checkout"). No two scenarios should share mutable state.

---

## Acceptance Scenarios:

---

### AC 1: Add-Item Entry Point — Bottom Sheet Presentation

- [ ] **Scenario: Tapping "Add another gift" presents AddItemOptionSheet instead of appending an item directly**
  - Given: `CreateWishlistPage2` is rendered and `CreateWishlistViewModel` holds zero or more items (test data namespace: `ac1-entry`)
  - When: The user taps the "Add another gift" button
  - Then: A bottom sheet view identified as `AddItemOptionSheet` is presented, exposing two distinct action options ("Paste a product link" and "Fill in manually"), and no new `WishlistItem` is appended to `viewModel.items` at this point
  - Verify:
    - `CreateWishlistPage2` has a state variable (e.g., `showAddItemSheet`) toggled to `true` by the button's action
    - `AddItemOptionSheet` is bound via `.sheet` or `.confirmationDialog` to that state variable
    - `CreateWishlistViewModel.items.count` remains unchanged until an option is chosen

---

### AC 2: Paste-Link Path — PasteLinkSheet Presentation

- [ ] **Scenario: Selecting "Paste a product link" opens PasteLinkSheet**
  - Given: `AddItemOptionSheet` is currently presented (test data namespace: `ac2-paste-link`)
  - When: The user taps the "Paste a product link" option
  - Then: `AddItemOptionSheet` is dismissed and `PasteLinkSheet` is presented, containing a URL input field and a submit/fetch trigger
  - Verify:
    - `AddItemOptionSheet`'s "paste link" action sets a state flag that triggers presentation of `PasteLinkSheet`
    - `PasteLinkSheet` contains a `TextField` (or equivalent) bound to a URL string property
    - A confirm/fetch button is present and enabled only when the URL field is non-empty

---

### AC 3: Loading State During Metadata Fetch

- [ ] **Scenario: Submitting a product URL shows a loading indicator while fetch is in progress**
  - Given: `PasteLinkSheet` is presented and the user has entered the URL `"https://example-ac3.com/product"` (test data namespace: `ac3-loading`)
  - When: The user taps the fetch/confirm button
  - Then: A loading indicator is visible in `PasteLinkSheet` and the submit button is disabled for the duration of the asynchronous fetch
  - Verify:
    - `CreateWishlistViewModel` (or the sheet's local state) has an `isFetching: Bool` property that is set to `true` before `await` and `false` in `defer` or after completion
    - `PasteLinkSheet` renders a `ProgressView` (or equivalent) conditioned on `isFetching == true`
    - The fetch button's `.disabled` modifier is bound to `isFetching`

---

### AC 4: Successful Fetch — Metadata Preview Displayed

- [ ] **Scenario: A successful fetch renders a metadata preview with all available fields**
  - Given: `PasteLinkSheet` initiates a fetch for URL `"https://example-ac4.com/product"` and `ProductMetadataService` returns a `ProductMetadata` value with title `"ac4-product-title"`, description `"ac4-product-description"`, image URL `"https://img.example-ac4.com/thumb.jpg"`, and price `"99.00"` (test data namespace: `ac4-preview`)
  - When: The fetch completes successfully
  - Then: `PasteLinkSheet` shows the title, description, image thumbnail, and price from the returned `ProductMetadata`; the loading indicator is hidden; and a confirm button is enabled
  - Verify:
    - `CreateWishlistViewModel` (or the sheet) exposes a `fetchedMetadata: ProductMetadata?` property populated after a successful fetch
    - `PasteLinkSheet` has conditional view blocks that render title, description, price, and an image view bound to `fetchedMetadata`
    - The confirm/add button is visible and enabled only when `fetchedMetadata != nil`

---

### AC 5: Fetch Failure — Human-Readable Error Message

- [ ] **Scenario: A failed fetch surfaces a human-readable error message in PasteLinkSheet**
  - Given: `PasteLinkSheet` initiates a fetch for URL `"https://fail-ac5.example.com/product"` and `ProductMetadataService` throws a network or parsing error (test data namespace: `ac5-error`)
  - When: The fetch completes with an error
  - Then: `PasteLinkSheet` displays a human-readable error string (not a raw system error code), the loading indicator is hidden, and no metadata preview is shown
  - Verify:
    - `CreateWishlistViewModel` (or the sheet) has a `fetchError: String?` property set to a user-facing message on failure
    - `PasteLinkSheet` renders the error message text conditionally on `fetchError != nil`
    - No `ProductMetadata` preview UI is rendered when an error is present

---

### AC 6: Confirm Auto-Fill — WishlistItem Appended from Metadata

- [ ] **Scenario: Confirming fetched metadata creates a new WishlistItem pre-filled from ProductMetadata**
  - Given: `PasteLinkSheet` has successfully fetched metadata with title `"ac6-product-title"`, description `"ac6-product-description"`, image URL `"https://img.example-ac6.com/thumb.jpg"`, price `"49.00"`, and source URL `"https://example-ac6.com/product"` (test data namespace: `ac6-confirm`)
  - When: The user taps the confirm/add button
  - Then: A new `WishlistItem` is appended to `CreateWishlistViewModel.items` with `name == "ac6-product-title"`, `description == "ac6-product-description"`, `image == "https://img.example-ac6.com/thumb.jpg"`, `price == "49.00"`, `itemLink == "https://example-ac6.com/product"`, and `localImage == nil`; `PasteLinkSheet` is dismissed
  - Verify:
    - The confirm action calls a method on `CreateWishlistViewModel` (e.g., `addItem(from:)`) that maps each `ProductMetadata` field to the corresponding `WishlistItem` property
    - `WishlistItem` has a `price: String?` field that is set from the metadata
    - The sheet's dismissal is triggered after the item is appended

---

### AC 7: Manual Entry Path — Empty WishlistItem Appended Directly

- [ ] **Scenario: Selecting "Fill in manually" bypasses PasteLinkSheet and appends an empty item**
  - Given: `AddItemOptionSheet` is presented (test data namespace: `ac7-manual`)
  - When: The user taps the "Fill in manually" option
  - Then: `AddItemOptionSheet` is dismissed, no `PasteLinkSheet` is shown, and exactly one new empty `WishlistItem` is appended to `CreateWishlistViewModel.items`
  - Verify:
    - `AddItemOptionSheet`'s "manual" action calls the same append logic used by the original "Add another gift" flow, producing a `WishlistItem` with all fields at their default/empty values
    - No `PasteLinkSheet` presentation flag is set by the manual path

---

### AC 8: Remote Image Rendered in WishlistItemCard When localImage Is Nil

- [ ] **Scenario: WishlistItemCard displays the remote image URL via WishieWebImage when localImage is nil**
  - Given: A `WishlistItem` with `localImage == nil` and `image == "https://img.example-ac8.com/thumb.jpg"` is rendered inside `WishlistItemCard` (test data namespace: `ac8-remote-image`)
  - When: `WishlistItemCard` computes its image view
  - Then: `WishieWebImage` is rendered using `item.image` as its URL source; no placeholder for `localImage` is shown
  - Verify:
    - `WishlistItemCard` has a conditional branch: `if let localImage = item.localImage { Image(uiImage:) } else { WishieWebImage(url: item.image) }`
    - `WishieWebImage` receives the non-nil `item.image` string/URL in the `else` branch

---

### AC 9: WishlistItem Model — Optional price Field and Backward Compatibility

- [ ] **Scenario: WishlistItem declares an optional price field and existing instances without price remain valid**
  - Given: The `WishlistItem` model definition (test data namespace: `ac9-model`)
  - When: A `WishlistItem` is instantiated without supplying a `price` argument
  - Then: The instance compiles successfully and `item.price` equals `nil`
  - Verify:
    - `WishlistItem` declares `var price: String?` (or `let price: String?`) with a default value of `nil`
    - Any `Codable` conformance uses `decodeIfPresent` (or equivalent) so that persisted items lacking the `price` key decode without error

---

### AC 10: Open Graph Fallback — title Tag Used When og:title Is Absent

- [ ] **Scenario: ProductMetadataService falls back to the HTML title tag when og:title is missing**
  - Given: `ProductMetadataService` receives HTML that contains `<title>ac10-page-title</title>` but no `<meta property="og:title" ...>` tag (test data namespace: `ac10-og-fallback`)
  - When: `parseMetadata(from:url:)` (or equivalent) processes the HTML
  - Then: The returned `ProductMetadata.title` equals `"ac10-page-title"`
  - Verify:
    - `ProductMetadataService` first attempts to read `og:title`; on absence it falls through to extract the content of `<title>`
    - A similar fallback for `og:url` → original request URL is also present in the parsing logic

---

### AC 11: MVVM Separation — Fetch Logic Resides in ViewModel, Not View

- [ ] **Scenario: ProductMetadataService is called from CreateWishlistViewModel, keeping views stateless coordinators**
  - Given: The source files for `CreateWishlistViewModel`, `PasteLinkSheet`, and `ProductMetadataService` (test data namespace: `ac11-mvvm`)
  - When: Code review inspects where the async fetch call is invoked
  - Then: The `URLSession`/`ProductMetadataService` call is inside `CreateWishlistViewModel`; `PasteLinkSheet` only binds to published properties and calls ViewModel methods
  - Verify:
    - `ProductMetadataService` (or its protocol) is a dependency of `CreateWishlistViewModel`, not of any View
    - `PasteLinkSheet` does not directly import or instantiate `ProductMetadataService`
    - `CreateWishlistViewModel` conforms to an `ObservableObject` and exposes `@Published` properties consumed by `PasteLinkSheet`

---

### AC 12: Protocol Abstraction — ProductMetadataServiceProtocol Separates Interface from Implementation

- [ ] **Scenario: CreateWishlistViewModel depends on ProductMetadataServiceProtocol, not the concrete type**
  - Given: The declarations of `ProductMetadataServiceProtocol`, `ProductMetadataService`, and `CreateWishlistViewModel` (test data namespace: `ac12-protocol`)
  - When: Code review inspects the ViewModel's stored property and initialiser
  - Then: `CreateWishlistViewModel` holds a reference typed as `ProductMetadataServiceProtocol`; `ProductMetadataService` conforms to `ProductMetadataServiceProtocol`; the concrete type is injected at call-site
  - Verify:
    - `CreateWishlistViewModel` has a property declared as `private let metadataService: ProductMetadataServiceProtocol`
    - `ProductMetadataService: ProductMetadataServiceProtocol` conformance exists
    - No direct reference to `ProductMetadataService` concrete type appears inside `CreateWishlistViewModel`'s method bodies
