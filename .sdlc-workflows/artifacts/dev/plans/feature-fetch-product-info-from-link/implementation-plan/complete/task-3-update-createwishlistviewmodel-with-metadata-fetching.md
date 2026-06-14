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

