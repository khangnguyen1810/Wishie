# Share Context

## Important Instructions for Implementation

- Follow MVVM: all async fetching and state mutation live in `CreateWishlistViewModel`; views only read published state and invoke view-model methods.
- Use protocol-based service abstraction: define `ProductMetadataServiceProtocol` and inject it into `CreateWishlistViewModel` via init, mirroring the existing `WishlistServiceProtocol` pattern.
- No code comments, no debug prints (`print`, `debugPrint`).
- Use native `URLSession` only — no third-party HTTP libraries.
- HTML parsing must use `NSRegularExpression` or `String` range-based search; no external HTML parsing libraries.
- Backward compatibility: `price: String?` is optional; existing Firestore documents without `price` must still decode correctly.
- UI must match existing design language: `.lightYellow` fills, `.wishiePink` accents, `Font.wishies(...)` typography, `RoundedRectangle(cornerRadius: 20)` card shapes.
- All new SwiftUI views use `@EnvironmentObject var createWishlistViewModel: CreateWishlistViewModel` for view model access — do not pass it as a regular parameter.
- Sheet dismissal is handled via `@Environment(\.dismiss)`.

## Reused Existing Functions/Utilities

- `WishieButton`: Reusable primary action button in `Wishie/CustomView/WishieButton.swift` — accepts `title`, `enabled`, `filColor`, `action`.
- `WishieWebImage`: Renders a remote image URL using SDWebImage in `Wishie/CustomView/WishieWebImage.swift` — accepts `url: String`.
- `ImagePickerBox`: Photo library picker wrapper in `Wishie/CustomView/ImagePickerBox.swift` — accepts `height`, `selectedImage: Binding<UIImage?>`.
- `BaseWishieScreen`: Top-level screen scaffold in `Wishie/Screens/BaseWishieScreen.swift`.
- `Font.wishies(_:_:)`: Custom font accessor in `Wishie/Resources/WishieCustomFont.swift`.
- `CreateWishlistViewModel.saveItem()`: Existing async method that uploads local images and persists the wishlist to Firestore in `Wishie/Screens/CreateList/CreateWishlistViewModel.swift`.

## Shared Contracts

### Entities

- `ProductMetadata`: Parsed Open Graph result. Fields: `title: String`, `productDescription: String`, `imageUrl: String?`, `productUrl: String`, `price: String?`. All fields are non-optional except `imageUrl` and `price`.
- `WishlistItem` (updated): Existing struct in `Wishie/Models/WishlistItem.swift` — add `price: String?` (default `nil`) alongside existing fields `id`, `name`, `description`, `image`, `localImage`, `itemLink`, `isPicked`, `isMostDesired`, `pickedUserId`.

### Interfaces

- `ProductMetadataServiceProtocol`: Protocol in `Wishie/Services/ProductMetadataService.swift`. Single method: `func fetchMetadata(from urlString: String) async throws -> ProductMetadata`. Throws on network failure or invalid URL. Does not throw if OG tags are partially missing — returns best-effort `ProductMetadata`.

### DTOs

None — `ProductMetadata` is used directly between the service and view model without a separate DTO layer.

---

# Task 1: Extend WishlistItem with price field

- [ ] 1.1: In `Wishie/Models/WishlistItem.swift` UPDATE:
  - Add `var price: String?` property to `WishlistItem` struct, positioned after `itemLink`.
  - Add `price: String? = nil` parameter to the memberwise `init(id:name:description:image:pickedUserId:isPicked:isMostDesired:localImage:itemLink:)`, positioned after `itemLink`.
  - Assign `self.price = price` in the init body.
  - In the `init(dictionary:)` extension initializer, add `self.price = dictionary["price"] as? String` (optional, no guard required since it is optional).

---

# Task 2: Create ProductMetadata model and ProductMetadataService

- [ ] 2.1: In `Wishie/Models/ProductMetadata.swift` CREATE:
  - Define `struct ProductMetadata` with fields: `title: String`, `productDescription: String`, `imageUrl: String?`, `productUrl: String`, `price: String?`.
  - No `Codable` or `Identifiable` conformance needed.

- [ ] 2.2: In `Wishie/Services/ProductMetadataService.swift` CREATE:
  - Define `protocol ProductMetadataServiceProtocol` with method `func fetchMetadata(from urlString: String) async throws -> ProductMetadata`.
  - Define `class ProductMetadataService: ProductMetadataServiceProtocol` that implements the protocol.
  - In `fetchMetadata(from urlString:)`:
    - Validate the URL using `URL(string: urlString)` — throw `URLError(.badURL)` if nil.
    - Build a `URLRequest` with the URL, set `User-Agent` header to `"Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"`, set `timeoutInterval` to `15`.
    - Fetch data using `URLSession.shared.data(for:)` — throw on non-2xx HTTP status codes by checking `(response as? HTTPURLResponse)?.statusCode`.
    - Convert data to `String` using UTF-8 encoding (fallback `latin1`).
    - Call private helper `extractMetadata(from html: String, originalUrl: String) -> ProductMetadata` to parse the HTML.
  - In `extractMetadata(from:originalUrl:)`:
    - Use a private helper `func extractMetaContent(from html: String, property: String) -> String?` that searches for `<meta property="PROPERTY" content="VALUE">` or `<meta content="VALUE" property="PROPERTY">` patterns using `NSRegularExpression` with case-insensitive matching.
    - Use a private helper `func extractMetaName(from html: String, name: String) -> String?` that searches for `<meta name="NAME" content="VALUE">` or `<meta content="VALUE" name="NAME">` patterns.
    - Use a private helper `func extractTitleTag(from html: String) -> String?` that extracts content between `<title>` and `</title>`.
    - Resolve title: `extractMetaContent(property: "og:title")` → fallback `extractTitleTag()` → fallback `"Unknown Product"`.
    - Resolve description: `extractMetaContent(property: "og:description")` → fallback `extractMetaName(name: "description")` → fallback `""`.
    - Resolve imageUrl: `extractMetaContent(property: "og:image")`.
    - Resolve productUrl: `extractMetaContent(property: "og:url")` → fallback `originalUrl`.
    - Resolve price: attempt `extractMetaContent(property: "product:price:amount")`, then `extractMetaContent(property: "og:price:amount")`. If found and a currency is also found via `extractMetaContent(property: "product:price:currency")` or `extractMetaContent(property: "og:price:currency")`, format as `"CURRENCY AMOUNT"` (e.g., `"USD 29.99"`); otherwise use the raw amount string.
    - Return `ProductMetadata(title:productDescription:imageUrl:productUrl:price:)`.

---

# Task 3: Update CreateWishlistViewModel with metadata fetching

- [ ] 3.1: In `Wishie/Screens/CreateList/CreateWishlistViewModel.swift` UPDATE:
  - Add `private var productMetadataService: ProductMetadataServiceProtocol` property.
  - Update `init(createWishListService:)` to `init(createWishListService: WishlistServiceProtocol = WishlistService(), productMetadataService: ProductMetadataServiceProtocol = ProductMetadataService())`, assigning both to their respective properties.
  - Add `@Published var isFetchingMetadata: Bool = false`.
  - Add `@Published var metadataFetchError: String? = nil`.
  - Add `func fetchProductMetadata(from urlString: String) async -> Result<ProductMetadata, Error>`:
    - Set `isFetchingMetadata = true`, clear `metadataFetchError`.
    - Call `await productMetadataService.fetchMetadata(from: urlString)` in a `do/catch`.
    - On success: set `isFetchingMetadata = false`, return `.success(metadata)`.
    - On failure: set `isFetchingMetadata = false`, set `metadataFetchError` to `error.localizedDescription`, return `.failure(error)`.
    - All state mutations must be dispatched on `@MainActor` — annotate the function `@MainActor`.
  - Add `func addItemFromMetadata(_ metadata: ProductMetadata)`:
    - Create a new `WishlistItem` with `name: metadata.title`, `description: metadata.productDescription`, `image: metadata.imageUrl`, `itemLink: metadata.productUrl`, `price: metadata.price`.
    - Append the item to `items`.

---

# Task 4: Create AddItemOptionSheet view

- [ ] 4.1: In `Wishie/Screens/CreateList/AddItemOptionSheet.swift` CREATE:
  - Define `struct AddItemOptionSheet: View`.
  - Accept two action closures via `let onPasteLink: () -> Void` and `let onManual: () -> Void`.
  - Body: a `VStack(spacing: 16)` with:
    - A drag handle `Capsule().fill(.gray.opacity(0.3)).frame(width: 40, height: 4)` at the top.
    - A title `Text("Add a gift idea")` styled `Font.wishies(.bold, 20)`.
    - An option card for "Paste a product link" using a `HStack` with `Image(systemName: "link")` icon (`.wishiePink` tint) and text labels: primary `Text("Paste a product link")` `.wishies(.bold, 16)` and secondary `Text("Auto-fill name, image & price from any site")` `.wishies(.regular, 13)` `.gray`. Background: `RoundedRectangle(cornerRadius: 16).fill(.white)` with a `.wishiePink.opacity(0.15)` border stroke, `lineWidth: 1.5`. `onTapGesture` calls `onPasteLink()`.
    - An option card for "Fill in manually" using the same structure with `Image(systemName: "pencil")` icon (`.black` tint) and labels: primary `Text("Fill in manually")` and secondary `Text("Add item details yourself")`. Background: `RoundedRectangle(cornerRadius: 16).fill(.white)` with `.black.opacity(0.08)` border. `onTapGesture` calls `onManual()`.
    - `.padding(.horizontal, 20).padding(.bottom, 32)`.
  - The sheet content sits inside a `VStack` with `.presentationDetents([.height(280)])` applied via `.presentationDetents` on the wrapping sheet call site (not in this view itself).

---

# Task 5: Create PasteLinkSheet view

- [ ] 5.1: In `Wishie/Screens/CreateList/PasteLinkSheet.swift` CREATE:
  - Define `struct PasteLinkSheet: View`.
  - Declare `@EnvironmentObject var createWishlistViewModel: CreateWishlistViewModel`.
  - Declare `@Environment(\.dismiss) private var dismiss`.
  - Declare `@State private var urlInput: String = ""`.
  - Declare `@State private var fetchedMetadata: ProductMetadata? = nil`.
  - Body layout (VStack, spacing 0):
    - **Header row**: drag handle `Capsule` + `Text("Paste a product link")` `.wishies(.bold, 20)`.
    - **URL input row**: `TextField("https://...", text: $urlInput)` with `.keyboardType(.URL)`, `.textInputAutocapitalization(.never)`, `.autocorrectionDisabled()`, styled with `.lightYellow` background `RoundedRectangle(cornerRadius: 12)`, plus a trailing "Fetch" `Button` styled with `.wishiePink` foreground — disabled when `urlInput.trimmingCharacters(in: .whitespaces).isEmpty || createWishlistViewModel.isFetchingMetadata`. The button triggers `performFetch()`.
    - **Loading state**: `if createWishlistViewModel.isFetchingMetadata` show `ProgressView("Fetching product info...")` centered.
    - **Error state**: `if let error = createWishlistViewModel.metadataFetchError` show `Text(error)` in `.red` font `.wishies(.regular, 13)`.
    - **Preview state**: `if let metadata = fetchedMetadata` show a preview card (`VStack(alignment: .leading, spacing: 8)`) containing:
      - If `metadata.imageUrl != nil`: `WishieWebImage(url: metadata.imageUrl!)` clipped to `RoundedRectangle(cornerRadius: 10)` with fixed height 140.
      - `Text(metadata.title)` `.wishies(.bold, 15)`.
      - If `!metadata.productDescription.isEmpty`: `Text(metadata.productDescription)` `.wishies(.regular, 13)` `.lineLimit(2)` `.foregroundStyle(.gray)`.
      - If `metadata.price != nil`: `Text(metadata.price!)` `.wishies(.bold, 14)` `.foregroundStyle(.wishiePink)`.
      - Background: `RoundedRectangle(cornerRadius: 14).fill(.white)` with shadow `radius: 6`.
    - **Action button**: `WishieButton(title: "Add to wishlist", enabled: fetchedMetadata != nil, action: { confirmAdd() })` with `.padding(.horizontal, 20)`.
    - `.padding(.bottom, 40)`.
  - Private method `performFetch()`:
    - Guard `let urlString = urlInput.trimmingCharacters(in: .whitespaces)`, not empty.
    - `fetchedMetadata = nil`.
    - Wrap in `Task { let result = await createWishlistViewModel.fetchProductMetadata(from: urlString); if case .success(let metadata) = result { fetchedMetadata = metadata } }`.
  - Private method `confirmAdd()`:
    - Guard `let metadata = fetchedMetadata`.
    - Call `createWishlistViewModel.addItemFromMetadata(metadata)` (uses `addItemFromMetadata` from task 3.1).
    - Call `dismiss()`.
  - Apply `.presentationDetents([.large])` at the call site.

---

# Task 6: Wire AddItemOptionSheet and PasteLinkSheet into CreateWishlistPage2

- [ ] 6.1: In `Wishie/Screens/CreateList/CreateWishlistPage2.swift` UPDATE `CreateWishlistPage2`:
  - Add `@State private var showAddItemOptionSheet: Bool = false`.
  - Add `@State private var showPasteLinkSheet: Bool = false`.
  - Change the `"Add another gift"` row's `.onTapGesture` from `createWishlistViewModel.items.append(WishlistItem())` to `showAddItemOptionSheet = true`.
  - Add `.sheet(isPresented: $showAddItemOptionSheet)` presenting `AddItemOptionSheet(onPasteLink: { showAddItemOptionSheet = false; showPasteLinkSheet = true }, onManual: { createWishlistViewModel.items.append(WishlistItem()); showAddItemOptionSheet = false })`.
  - Add `.sheet(isPresented: $showPasteLinkSheet)` presenting `PasteLinkSheet().environmentObject(createWishlistViewModel).presentationDetents([.large])`.

- [ ] 6.2: In `Wishie/Screens/CreateList/CreateWishlistPage2.swift` UPDATE `WishlistItemCard`:
  - In the `ImagePickerBox` content closure, add an `else if let remoteUrl = item.image, !remoteUrl.isEmpty` branch between the `if let selectedImage = item.localImage` branch and the upload placeholder `else` branch.
  - The new branch renders `WishieWebImage(url: remoteUrl).frame(maxWidth: .infinity, minHeight: 180).clipped()`, styled identically to the `localImage` branch (same frame, clipped, `.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))`).
  - Add a `price` text field below the `itemLink` text field: `TextField("Price (optional)", text: Binding(get: { item.price ?? "" }, set: { item.price = $0.isEmpty ? nil : $0 }))` styled with `.wishies(.regular, 15)`, `.lightYellow` background `RoundedRectangle(cornerRadius: 10)`, `.focused($focusedField, equals: .price)`.
  - Add `.price` to `CreateWishlistItemField` enum.
  - Import `SDWebImageSwiftUI` is not needed here — `WishieWebImage` encapsulates the dependency.
