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

