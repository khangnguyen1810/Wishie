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

# Task 1: Extend `WishlistItem` model with `isMostDesired` field

- [ ] 1.1: In `Wishie/Models/WishlistItem.swift` UPDATE:
  - Add `var isMostDesired: Bool` property to the `WishlistItem` struct body, positioned after `isPicked: Bool`.
  - Add `isMostDesired: Bool = false` parameter to the designated `init(id:name:description:image:pickedUserId:isPicked:localImage:itemLink:)`, positioned after `isPicked`.
  - Assign `self.isMostDesired = isMostDesired` in the initializer body.
  - In the `init(dictionary:)` extension initializer, parse `self.isMostDesired = dictionary["isMostDesired"] as? Bool ?? false` after the `self.itemLink` assignment.

---

# Task 2: Add `deleteWishlistItem` and `setMostDesired` to the service layer

- [ ] 2.1: In `Wishie/Services/WishlistService.swift` UPDATE — `WishlistServiceProtocol`:
  - Append `func deleteWishlistItem(wishlistId: String, itemId: String) async throws -> Result<Bool, Error>` to the protocol body.
  - Append `func setMostDesired(wishlistId: String, itemId: String, isMostDesired: Bool) async throws -> Result<Bool, Error>` to the protocol body.

- [ ] 2.2: In `Wishie/Services/WishlistService.swift` UPDATE — `WishlistService` implementation:
  - Implement `deleteWishlistItem(wishlistId:itemId:)` following the same `do/catch → Result` pattern used by `pickItem(wishlistId:itemId:)`:
    - Obtain `docRef` for `db.collection("wishList").document(wishlistId)`.
    - Fetch the document snapshot and guard-unwrap `data["wishListItems"] as? [[String: Any]]`.
    - Filter out the element whose `"id"` key equals `itemId`.
    - Call `docRef.updateData(["wishListItems": filteredItems])`.
    - Return `.success(true)` on success and `.failure(error)` in the `catch`.
  - Implement `setMostDesired(wishlistId:itemId:isMostDesired:)` following the same pattern used by `updateWishlistItem(wishlistId:itemId:newName:newDescription:newImage:)`:
    - Fetch and guard-unwrap `wishListItems` from the document.
    - Iterate over item indices; when `items[index]["id"] == itemId`, set `items[index]["isMostDesired"] = isMostDesired` and break.
    - Call `docRef.updateData(["wishListItems": items])`.
    - Return `.success(true)` on success and `.failure(error)` in the `catch`.

---

# Task 3: Extend `WishlistDetailViewController` with delete and most-desired actions

- [ ] 3.1: In `Wishie/Screens/Detail/WishlistDetailViewController.swift` UPDATE:
  - Add `@Published var showDeleteConfirmation: Bool = false` after the existing `@Published var joinErrorMessage: String = ""`.
  - Add `@Published var showReserveConfirmation: Bool = false` directly after `showDeleteConfirmation`.
  - Implement `func deleteWishlistItem(wishlistId: String) async` following the pattern of `pickItem(wishlistId:)`:
    - Set `isShowLoading = true`.
    - Call `try await wishlistService.deleteWishlistItem(wishlistId: wishlistId, itemId: itemSelected.id)`.
    - On `.success`: set `isShowLoading = false` and call `await getWishlistInfo(wishListId: wishlistId)`.
    - On `.failure(let error)`: set `isShowLoading = false`, `errorMessage = error.localizedDescription`, `isShowError = true`.
    - In the `catch`: set `isShowLoading = false`, `errorMessage = error.localizedDescription`, `isShowError = true`.
  - Implement `func setMostDesired(wishlistId: String) async` following the same pattern:
    - Set `isShowLoading = true`.
    - Call `try await wishlistService.setMostDesired(wishlistId: wishlistId, itemId: itemSelected.id, isMostDesired: true)`.
    - On `.success`: set `isShowLoading = false` and call `await getWishlistInfo(wishListId: wishlistId)`.
    - On `.failure(let error)` and in `catch`: set `isShowLoading = false`, `errorMessage = error.localizedDescription`, `isShowError = true`.

---

# Task 4: Add gift-selection progress indicator to the `WishlistDetailScreen` header

- [ ] 4.1: In `Wishie/Screens/Detail/WishlistDetailScreen.swift` UPDATE — `headerContent()` `@ViewBuilder` method:
  - Compute `let pickedCount = viewModel.wishlistInfo.items.filter(\.isPicked).count` and `let totalCount = viewModel.wishlistInfo.items.count` at the top of the method body.
  - Compute `let progress = totalCount > 0 ? Double(pickedCount) / Double(totalCount) : 0.0`.
  - Inside the outer `VStack`, after the existing `HStack` (item count + date row) and before the description `Text`, insert a new `HStack` containing:
    - `GiftProgressView(progress: progress)` sized to `.frame(width: 32, height: 32)`.
    - A `Text("\(pickedCount) / \(totalCount) gifts selected")` styled with `.font(.wishies(.regular, 14))` and `.foregroundStyle(.darkGrey)`.
    - `Spacer()` to push the indicator to the leading edge.

---

# Task 5: Migrate `listContent()` to a native SwiftUI `List` with swipe-to-delete and star badge

- [ ] 5.1: In `Wishie/Screens/Detail/WishlistDetailScreen.swift` UPDATE — `listContent()` `@ViewBuilder` method:
  - Replace the outer `VStack()` container with `List` and apply `.listStyle(.plain)` and `.scrollContentBackground(.hidden)` modifiers on the `List`.
  - Remove the `.padding(.horizontal, 15)` and `.padding(.top, 15)` from the outer call-site `VStack` that wraps `headerContent()` and `listContent()`, because `List` manages its own insets; instead apply `.listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))` and `.listRowBackground(Color.clear)` on each row.
  - Keep the existing `HStack` row content (thumbnail `WebImage`, item name `Text`, picked user icon) unchanged.
  - Add a star badge to the item row: inside the `HStack`, after the item name `Text` and before the picked-user icon section, add `if item.isMostDesired { Image(systemName: "star.fill").foregroundStyle(.yellow).frame(width: 16, height: 16) }`.
  - Attach `.swipeActions(edge: .trailing, allowsFullSwipe: false)` to each row; inside, add a single `Button(role: .destructive)` labelled with `Label("Delete", systemImage: "trash")` that executes `viewModel.itemSelected = item` then `viewModel.showDeleteConfirmation = true`. Render this action only when `viewModel.wishlistInfo.isOwner() == true && !item.isPicked`.

---

# Task 6: Update owner's bottom sheet with "Mark as Most Desired" and "Delete" CTAs

- [ ] 6.1: In `Wishie/Screens/Detail/WishlistDetailScreen.swift` UPDATE — `bottomSheet()` `@ViewBuilder` method, inside the `if wishlist?.isOwner() == true` branch, within the `VStack` that currently holds the Edit/Save button and Cancel button:
  - After the Edit/Save `ZStack` button (and its conditional Cancel button), add a "Mark as Most Desired" button using the same `ZStack`/`RoundedRectangle` pattern as the existing buttons:
    - Background: `Color(hex: viewModel.wishlistInfo.theme.secondary)`, height `45`, corner radius `15`.
    - Leading icon: `Image(systemName: "star.fill")` sized to `25` wide with `.padding(.leading, 20)`.
    - Center label: `Text("Mark as Most Desired")` styled `.font(.wishies(.bold, 15))` and `.foregroundStyle(.black)`.
    - Visibility: only shown when `!viewModel.itemSelected.isMostDesired && !isEditing`.
    - `onTapGesture`: calls `Task { await viewModel.setMostDesired(wishlistId: wishlist?.id ?? "") }` then dismisses the sheet by setting `viewModel.showBottomSheet = false`.
  - After the "Mark as Most Desired" button, add a "Delete" button:
    - Background: `.wishiePink` when `!viewModel.itemSelected.isPicked`, else `.lightGrey`.
    - Leading icon: `Image(systemName: "trash")` sized to `25` wide with `.padding(.leading, 20)`.
    - Center label: `Text("Delete")` styled `.font(.wishies(.bold, 15))` and `.foregroundStyle(.black)`.
    - Visibility: only shown when `!isEditing`.
    - Interaction: disabled (`.disabled(viewModel.itemSelected.isPicked)`) when the item is already picked.
    - `onTapGesture`: sets `viewModel.showDeleteConfirmation = true` when `!viewModel.itemSelected.isPicked`.

---

# Task 7: Wire confirmation dialogs for member reserve and owner delete

- [ ] 7.1: In `Wishie/Screens/Detail/WishlistDetailScreen.swift` UPDATE — `reserveButton()` `@ViewBuilder` method:
  - Replace the direct `await viewModel.pickItem(wishlistId:)` call inside `onTapGesture` with `viewModel.showReserveConfirmation = true` (only when `!viewModel.itemSelected.isPicked`). The actual `pickItem` call is triggered from the dialog's `onOk` closure (added in 7.2).

- [ ] 7.2: In `Wishie/Screens/Detail/WishlistDetailScreen.swift` UPDATE — `body` computed property:
  - Add a `showDialogIfNeeded` modifier for `$viewModel.showReserveConfirmation` chained after the existing `.showDialogIfNeeded($showLinkNotValidOrNotExist, ...)` modifier:
    - `title: "Reserve this gift?"`, `message: "Do you want to select this gift?"`, `showCancel: true`.
    - `onOk`: `{ Task { viewModel.showBottomSheet = false; let wId = viewModel.wishlistInfo.id; await viewModel.pickItem(wishlistId: wId) } }`.
    - `onCancel`: `nil` (dialog dismisses with no side effects).
  - Add a `showDialogIfNeeded` modifier for `$viewModel.showDeleteConfirmation` chained immediately after:
    - `title: "Delete item?"`, `message: "This action cannot be undone."`, `showCancel: true`.
    - `onOk`: `{ Task { viewModel.showBottomSheet = false; let wId = viewModel.wishlistInfo.id; await viewModel.deleteWishlistItem(wishlistId: wId) } }`.
    - `onCancel`: `nil`.
