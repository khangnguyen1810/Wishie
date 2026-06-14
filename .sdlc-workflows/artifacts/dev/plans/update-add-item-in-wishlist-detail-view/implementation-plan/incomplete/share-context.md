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

