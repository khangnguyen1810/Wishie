# Task 4: Create AddItemPasteLinkDetailSheet

- [ ] 4.1: In `Wishie/Screens/Detail/AddItemPasteLinkDetailSheet.swift` CREATE:
  - Define `struct AddItemPasteLinkDetailSheet: View` with `@ObservedObject var viewModel: WishlistDetailViewController` and `let wishlistId: String`.
  - Add `@Environment(\.dismiss) private var dismiss` and `@State private var urlInput: String = ""`.
  - Body: `VStack(spacing: 0)` containing:
    - Drag indicator same as `AddItemManualDetailSheet`.
    - Title: `Text("Paste a product link").font(.wishies(.bold, 20)).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.bottom, 16)`.
    - URL input row: `HStack(spacing: 10)` with `TextField("https://...", text: $urlInput)` (`.keyboardType(.URL)`, `.textInputAutocapitalization(.never)`, `.autocorrectionDisabled()`, `.font(.wishies(.regular, 15))`, background `.lightYellow`, `clipShape(RoundedRectangle(cornerRadius: 12))`) and a `Button("Fetch") { Task { await viewModel.fetchProductMetadataForNewItem(from: urlInput.trimmingCharacters(in: .whitespaces)) } }` styled `.font(.wishies(.bold, 15)).foregroundStyle(.wishiePink)`, disabled when `urlInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isFetchingMetadata`. Padded `.horizontal, 20` and `.bottom, 16`.
    - `if viewModel.isFetchingMetadata { ProgressView("Fetching product info...").frame(maxWidth: .infinity).padding(.vertical, 16) }`.
    - `if let error = viewModel.metadataFetchError { Text(error).font(.wishies(.regular, 13)).foregroundStyle(.red).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.bottom, 12) }`.
    - Metadata preview: `if viewModel.newItemName != ""` show a `VStack(alignment: .leading, spacing: 8)` inside a white card (`RoundedRectangle` with shadow) containing: `WishieWebImage(url: viewModel.newItemRemoteImageUrl ?? "").frame(height: 140).clipShape(RoundedRectangle(cornerRadius: 10))` (only if `viewModel.newItemRemoteImageUrl != nil`), `Text(viewModel.newItemName).font(.wishies(.bold, 15))`, `Text(viewModel.newItemDescription).font(.wishies(.regular, 13)).lineLimit(2).foregroundStyle(.gray)` if non-empty. Padded `.horizontal, 20` and `.bottom, 16`.
    - `Spacer()`.
    - `WishieButton(title: "Add to wishlist", enabled: !viewModel.newItemName.trimmingCharacters(in: .whitespaces).isEmpty)` with action: `Task { await viewModel.addNewWishlistItem(wishlistId: wishlistId); dismiss() }`. Padded `.horizontal, 20` and `.bottom, 40`.
  - Apply `.ignoresSafeArea(.keyboard, edges: .bottom)` to the outer `VStack`.

