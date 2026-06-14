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

