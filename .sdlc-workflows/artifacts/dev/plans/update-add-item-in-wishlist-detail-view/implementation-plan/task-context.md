# Share Context

## Important Instructions for Implementation

- All business logic and async operations belong in `WishlistDetailViewController`; views are layout and interaction only.
- iOS does not support presenting a sheet from within another dismissing sheet. Use `DispatchQueue.main.asyncAfter(deadline: .now() + 0.3)` to delay presenting the second sheet after dismissing the first, following the same pattern used for `showDeleteConfirmation` and `showReserveConfirmation` in `WishlistDetailScreen`.
- The `AddItemOptionSheet` component in `Wishie/Screens/CreateList/AddItemOptionSheet.swift` must be reused without modification.
- `PasteLinkSheet` in `Wishie/Screens/CreateList/PasteLinkSheet.swift` is tightly coupled to `CreateWishlistViewModel` and must NOT be reused; create a separate `AddItemPasteLinkDetailSheet` instead.
- Upload the image to Supabase storage first (via `WishlistService.upload(image:fileName:)`), then call `addWishlistItem` with the returned URL as `item.image`. Only proceed with `addWishlistItem` after a successful image upload.
- After a successful add, reset all new-item published state: `newItemName`, `newItemDescription`, `newItemImage`, `newItemLink`, `metadataFetchError`.

## Reused Existing Functions/Utilities

- `WishlistService.upload(image:fileName:)`: Uploads a `UIImage` to Supabase storage and returns the public URL string. Located in `Wishie/Services/WishlistService.swift`.
- `AddItemOptionSheet(onPasteLink:onManual:)`: Callback-based sheet presenting two add-item options. Located in `Wishie/Screens/CreateList/AddItemOptionSheet.swift`.
- `ImagePickerBox(height:selectedImage:content:)`: Custom view wrapping `PHPickerViewController` for image selection. Located in `Wishie/CustomView/ImagePickerBox.swift`.
- `WishieButton(title:enabled:height:horizontalPadding:action:)`: Primary action button component. Located in `Wishie/CustomView/WishieButton.swift`.
- `WishieWebImage(url:)`: Async image loader using SDWebImage. Located in `Wishie/CustomView/WishieWebImage.swift`.
- `ProductMetadataService.fetchMetadata(from:)`: Fetches `ProductMetadata` by scraping Open Graph tags from a URL. Located in `Wishie/Services/ProductMetadataService.swift`.

## Shared Contracts

### Entities

- `WishlistItem`: Represents a single item in a wishlist. Fields: `id: String` (UUID), `name: String`, `description: String`, `image: String?` (remote URL), `pickedUserId: String?`, `isPicked: Bool`, `isMostDesired: Bool`, `localImage: UIImage?` (transient), `itemLink: String`, `price: String?`. Defined in `Wishie/Models/WishlistItem.swift`.
- `ProductMetadata`: Scraped metadata from a product URL. Fields: `title: String`, `productDescription: String`, `imageUrl: String?`, `productUrl: String`, `price: String?`. Defined in `Wishie/Models/ProductMetadata.swift`.

### Interfaces

- `WishlistServiceProtocol`: Contract for wishlist persistence. Defined in `Wishie/Services/WishlistService.swift`. The new `addWishlistItem(wishlistId:item:)` method is added in Task 1.
- `ProductMetadataServiceProtocol`: Contract for fetching product metadata. Single method `fetchMetadata(from urlString: String) async throws -> ProductMetadata`. Defined in `Wishie/Services/ProductMetadataService.swift`.

### DTOs

- N/A. `WishlistItem` is used directly as the data carrier for new items.

---

# Task 1: Extend WishlistService with addWishlistItem

- [ ] 1.1: In `Wishie/Services/WishlistService.swift` UPDATE:
  - Add `func addWishlistItem(wishlistId: String, item: WishlistItem) async throws -> Result<Bool, Error>` to `WishlistServiceProtocol`.
  - Implement `addWishlistItem` in `WishlistService`: fetch the Firestore document for `wishlistId` from the `"wishList"` collection, append a new item dictionary to `wishListItems` using `FieldValue.arrayUnion`, and call `updateData`. The item dictionary must include keys `id`, `name`, `description`, `imageUrl`, `isPicked`, `itemLink`, `price`, `isMostDesired` — matching the schema used in `createWishlist` and `updateWishlistItem`.

# Task 2: Add Add-Item State and Logic to WishlistDetailViewController

- [ ] 2.1: In `Wishie/Screens/Detail/WishlistDetailViewController.swift` UPDATE:
  - Add `@Published var showAddItemOptionSheet: Bool = false` to published properties.
  - Add `@Published var showAddItemManualSheet: Bool = false` to published properties.
  - Add `@Published var showAddItemPasteLinkSheet: Bool = false` to published properties.
  - Add `@Published var newItemName: String = ""` to published properties.
  - Add `@Published var newItemDescription: String = ""` to published properties.
  - Add `@Published var newItemImage: UIImage? = nil` to published properties.
  - Add `@Published var newItemLink: String = ""` to published properties.
  - Add `@Published var isFetchingMetadata: Bool = false` to published properties.
  - Add `@Published var metadataFetchError: String? = nil` to published properties.
  - Add `private var productMetadataService: ProductMetadataServiceProtocol` stored property.
  - Update `init(wishlistService:authService:)` to also accept `productMetadataService: ProductMetadataServiceProtocol = ProductMetadataService()` and assign it.
  - Add `func addNewWishlistItem(wishlistId: String) async`: builds a `WishlistItem` from `newItemName`, `newItemDescription`, `newItemLink`; if `newItemImage` is non-nil, calls `wishlistService.upload(image:fileName:)` first and assigns the URL to `item.image`; then calls `wishlistService.addWishlistItem(wishlistId:item:)`; on success resets `newItemName`, `newItemDescription`, `newItemImage`, `newItemLink`, `metadataFetchError`; on failure sets `errorMessage` and `isShowError = true`. Sets `isShowLoading = true` at entry and `isShowLoading = false` before returning in all branches.
  - Add `func fetchProductMetadataForNewItem(from urlString: String) async`: sets `isFetchingMetadata = true` and `metadataFetchError = nil`; calls `productMetadataService.fetchMetadata(from: urlString)`; on success calls `setNewItemFromMetadata(_:)`; on failure sets `metadataFetchError = error.localizedDescription`; sets `isFetchingMetadata = false` in all branches.
  - Add `func setNewItemFromMetadata(_ metadata: ProductMetadata)`: assigns `newItemName = metadata.title`, `newItemDescription = metadata.productDescription`, `newItemLink = metadata.productUrl`; if `metadata.imageUrl` is non-nil also stores it in `newItemLink` is NOT correct — stores the image URL string into a temporary `@Published var newItemRemoteImageUrl: String? = nil` published property (add this property too), so the paste link sheet can show the preview image and include it in the final item.
  - **Correction for metadata image**: Add `@Published var newItemRemoteImageUrl: String? = nil`. In `setNewItemFromMetadata`, set `newItemRemoteImageUrl = metadata.imageUrl`. In `addNewWishlistItem`, if `newItemImage != nil` upload it (takes priority); otherwise use `newItemRemoteImageUrl` as `item.image` directly (no upload needed since it's already a remote URL). Reset `newItemRemoteImageUrl` in the success reset block.

# Task 3: Create AddItemManualDetailSheet

- [ ] 3.1: In `Wishie/Screens/Detail/AddItemManualDetailSheet.swift` CREATE:
  - Define `struct AddItemManualDetailSheet: View` with `@ObservedObject var viewModel: WishlistDetailViewController` and `let wishlistId: String` as properties.
  - Add `@Environment(\.dismiss) private var dismiss`.
  - Body: `VStack(spacing: 0)` containing:
    - Drag indicator: `Capsule().fill(Color.gray.opacity(0.4)).frame(width: 40, height: 5).padding(.top, 12).padding(.bottom, 16)`.
    - Title: `Text("Add a gift idea").font(.wishies(.bold, 20)).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.bottom, 16)`.
    - `ImagePickerBox(height: 160, selectedImage: $viewModel.newItemImage)` wrapping a placeholder `ZStack` that shows `Image(uiImage:)` if `viewModel.newItemImage != nil`, else a `VStack` with `Image("upload")` and `Text("Add photo")`. Style: `RoundedRectangle(cornerRadius: 12)`, background `.wishiePink`, clipped. Padded `.horizontal, 20`.
    - `TextField("Item name", text: $viewModel.newItemName)` styled with `.font(.wishies(.bold, 17))`, `.padding(.horizontal, 12)`, `.padding(.vertical, 10)`, `.background(.lightYellow)`, `.clipShape(RoundedRectangle(cornerRadius: 10))`. Padded `.horizontal, 20`.
    - `TextField("About this item...", text: $viewModel.newItemDescription, axis: .vertical)` styled with `.font(.wishies(.italic, 14))`, `.lineLimit(2...4)`, `.frame(height: 74, alignment: .topLeading)`, same background and clip as name field. Padded `.horizontal, 20`.
    - `TextField("Paste product link", text: $viewModel.newItemLink)` styled with `.font(.wishies(.regular, 15))`, `.keyboardType(.URL)`, `.textInputAutocapitalization(.never)`, `.autocorrectionDisabled()`, same background and clip. Padded `.horizontal, 20`.
    - `Spacer()`.
    - `WishieButton(title: "Add to wishlist", enabled: !viewModel.newItemName.trimmingCharacters(in: .whitespaces).isEmpty)` with action: `Task { await viewModel.addNewWishlistItem(wishlistId: wishlistId); dismiss() }`. Padded `.horizontal, 20` and `.bottom, 40`.
  - Apply `.ignoresSafeArea(.keyboard, edges: .bottom)` to the outer `VStack`.

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

# Task 5: Add FAB Button and Sheet Wiring to WishlistDetailScreen

- [ ] 5.1: In `Wishie/Screens/Detail/WishlistDetailScreen.swift` UPDATE:
  - In the `ZStack(alignment: .bottom)` body, add after the `StickyHeaderView(...)` block and after the `if viewModel.wishlistInfo.isUserJoined() == false` block, a new conditional:
    ```swift
    if viewModel.wishlistInfo.isOwner() {
        Button {
            viewModel.showAddItemOptionSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 50, height: 50)
                .background(Color(hex: viewModel.wishlistInfo.theme.secondary))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
        .padding(.bottom, 24)
        .padding(.trailing, 20)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    ```
  - Add `.sheet(isPresented: $viewModel.showAddItemOptionSheet)` modifier (after existing `.sheet` modifiers) presenting `AddItemOptionSheet` with `.presentationDetents([.height(280)])`:
    - `onPasteLink`: dismiss option sheet (`viewModel.showAddItemOptionSheet = false`), then after `0.3s` delay set `viewModel.showAddItemPasteLinkSheet = true`.
    - `onManual`: dismiss option sheet (`viewModel.showAddItemOptionSheet = false`), then after `0.3s` delay set `viewModel.showAddItemManualSheet = true`.
  - Add `.sheet(isPresented: $viewModel.showAddItemManualSheet)` presenting `AddItemManualDetailSheet(viewModel: viewModel, wishlistId: wishlist?.id ?? wishlistId ?? "")` with `.presentationDetents([.large])`.
  - Add `.sheet(isPresented: $viewModel.showAddItemPasteLinkSheet)` presenting `AddItemPasteLinkDetailSheet(viewModel: viewModel, wishlistId: wishlist?.id ?? wishlistId ?? "")` with `.presentationDetents([.large])`.
  - On dismiss of `showAddItemManualSheet` and `showAddItemPasteLinkSheet`, reset transient state by setting `viewModel.newItemName = ""`, `viewModel.newItemDescription = ""`, `viewModel.newItemImage = nil`, `viewModel.newItemLink = ""`, `viewModel.newItemRemoteImageUrl = nil`, `viewModel.metadataFetchError = nil`. Use the `onDismiss:` parameter of `.sheet(isPresented:onDismiss:content:)` for this.
