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

