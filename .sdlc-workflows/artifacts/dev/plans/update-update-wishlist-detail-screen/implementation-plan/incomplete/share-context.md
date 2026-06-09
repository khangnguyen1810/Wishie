# Share Context

## Important Instructions for Implementation

- All new logic (backend calls, state transitions) must live in `WishlistDetailViewController`; `WishlistDetailScreen` views remain declarative and stateless.
- Follow the existing post-mutation refresh pattern: after any state-changing backend call (delete, mark most desired, pick item), call `getWishlistInfo(wishListId:)` to re-sync `wishlistInfo`.
- The `isMostDesired` field defaults to `false` so existing Firestore documents with no such key remain valid without migration.
- The swipe-to-delete list migration replaces the `ForEach`-in-`VStack` inside `listContent()` with a native SwiftUI `List`. Apply `.listStyle(.plain)` and `.scrollContentBackground(.hidden)` to preserve visual continuity with the existing layout.
- Use the existing `showDialogIfNeeded` View extension from `Wishie/CustomView/DialogView.swift` for all confirmation dialogs; supply `showCancel: true` and the appropriate `onOk` closure.
- Never add `print` statements, `TODO` comments, or debug code.

## Reused Existing Functions/Utilities

- `getWishlistInfo(wishListId:)`: Async method on `WishlistDetailViewController` that refreshes `wishlistInfo` from Firestore. Called after every state-changing backend operation. Located in `Wishie/Screens/Detail/WishlistDetailViewController.swift`.
- `showDialogIfNeeded(_:title:message:showCancel:onOk:onCancel:)`: `View` extension on `Wishie/CustomView/DialogView.swift` that overlays a `DialogView` when the binding is `true`. Used for all confirmation dialogs.
- `showFullScreenDialog(_:)`: `View` extension on `Wishie/CustomView/DialogView.swift` that overlays a full-screen loading spinner tied to `viewModel.isShowLoading`.
- `WishlistModel.getItemsRemaining()`: Computed method returning the count of unpicked items; use `items.filter(\.isPicked).count` for picked count. Located in `Wishie/Models/WishlistModel.swift`.
- `WishlistModel.isOwner()`: Returns `true` when the current user's ID maps to `WishlistRole.owner` in `members`. Located in `Wishie/Models/WishlistModel.swift`.
- `GiftProgressView(progress:)`: Reusable progress view accepting a `Double` in `[0, 1]`. Located in `Wishie/CustomView/GiftProgressView.swift`.

## Shared Contracts

### Entities

- `WishlistItem`: Represents a single item in a wishlist. Fields (after Task 1):
  - `id: String` — unique identifier (UUID string); required, non-empty
  - `name: String` — display name; required
  - `description: String` — optional detail text; defaults to `""`
  - `image: String?` — Supabase storage URL; optional
  - `pickedUserId: String?` — ID of the member who reserved the item; `nil` when unreserved
  - `isPicked: Bool` — `true` when reserved; defaults to `false`
  - `isMostDesired: Bool` — owner-set flag indicating highest priority; defaults to `false`; Firestore field key `"isMostDesired"`
  - `localImage: UIImage?` — transient local image for edit flow; not persisted
  - `itemLink: String` — product URL string; defaults to `""`

### Interfaces

- `WishlistServiceProtocol` (in `Wishie/Services/WishlistService.swift`): Service interface for all wishlist backend operations. After Task 2, includes:
  - `deleteWishlistItem(wishlistId: String, itemId: String) async throws -> Result<Bool, Error>` — removes the item with `itemId` from the `wishListItems` array in the Firestore `wishList` document identified by `wishlistId`.
  - `setMostDesired(wishlistId: String, itemId: String, isMostDesired: Bool) async throws -> Result<Bool, Error>` — sets the `isMostDesired` field of the item with `itemId` in the Firestore `wishListItems` array to `isMostDesired`.

---

