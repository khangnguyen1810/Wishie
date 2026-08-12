# Wishlist Creation — API Migration — Design

## Context

Today, `CreateWishlistViewModel.saveItem()` (`Wishie/Screens/CreateList/CreateWishlistViewModel.swift:26-52`) pre-uploads every item's local image straight to Supabase Storage (`WishlistService.upload(image:fileName:)`), then calls `WishlistService.createWishlist(wishList:)` (`Wishie/Services/WishlistService.swift:77-122`), which writes the wishlist document, its items array, and the owner's membership directly to Firestore across two separate document writes.

The NestJS backend (`wishie-server`, documented in `API.md`) has a working `POST /wishlists` endpoint that creates the wishlist, its owner membership, and any provided items atomically in one call, with a client-generated UUID `id` (already how this app generates ids — `WishlistModel`/`WishlistItem` default `id: String = UUID().uuidString`, so no id-generation change is needed). Critically, `POST /wishlists`'s `items` array **does not accept an image** — a per-item image must be attached afterward via a separate multipart call, `PATCH /wishlists/:wishlistId/items/:itemId`.

This slice follows the same incremental pattern as the prior list migration (`2026-08-10-wishlist-list-migration-design.md`): one `WishlistServiceProtocol` method moves to the API at a time, reusing the existing `APIRoute`/`APIService`/`APIError`/`WishieDateFormatting` networking layer, while every other method on `WishlistService` (`getWishlist(by:)`, `joinWishlist`, item CRUD, `observeWishlist`, `observeUserWishlistIds`, etc.) stays Firestore-backed, untouched.

## Goal

Replace `WishlistService.createWishlist`'s Firestore internals with `POST /wishlists` (plus a best-effort per-item image upload pass afterward), preserving the existing 3-step creation UI (`CreateWishListScreen`/`CreateWishlistPage1-3`) and its navigation to `CreateWishlistSuccessScreen` with minimal view-layer changes.

## Approach

### Networking: multipart support on `APIRoute`

Two new cases are added to the existing `APIRoute: URLRequestConvertible` enum:

```swift
case createWishlist(CreateWishlistRequest)
case uploadItemImage(wishlistId: String, itemId: String, imageData: Data)
```

`.createWishlist` builds `POST /wishlists` with a JSON body, the same way `.signup`/`.login` already do. `.uploadItemImage` builds the `PATCH /wishlists/:wishlistId/items/:itemId` URL/method/auth header only — `asURLRequest()` does not set a JSON body for it. A new computed property carries the multipart payload:

```swift
var multipartFormData: ((MultipartFormData) -> Void)? {
    switch self {
    case .uploadItemImage(_, _, let imageData):
        return { form in
            form.append(imageData, withName: "file", fileName: "image.jpg", mimeType: "image/jpeg")
        }
    default:
        return nil
    }
}
```

`APIService.send<T>` branches on this property: when non-nil, dispatch via `session.upload(multipartFormData:with:)` instead of `session.request(route)`; the rest of the response/error handling (`.validate()`, `APIError.decodeServerError`, JSON decoding into `T`) is unchanged and shared between both dispatch paths. This keeps `APIRoute` the single source of truth for every endpoint (per the existing convention) without adding a second method to `APIServiceProtocol`.

### File organization: `APIRequest.swift` / `APIResponse.swift`

All request DTOs consolidate into `Wishie/Models/APIRequest.swift`; all response DTOs consolidate into `Wishie/Models/APIResponse.swift`. Struct names are unchanged (`SignUpRequest`, `WishlistResponse`, `WishlistItemResponse`, `WishlistMemberResponse`, `ProfileResponse`, plus the two new ones below), so no call site changes — this is a pure file reorganization, extending the existing precedent that `WishlistResponse.swift` already bundles three related structs in one file. The old `SignUpRequest.swift`, `WishlistResponse.swift`, `ProfileResponse.swift` files are deleted; their contents move into the two new files.

Two new structs are added to `APIRequest.swift`:

```swift
struct CreateWishlistRequest: Encodable {
    let id: String
    let name: String
    let description: String
    let dueDate: String        // WishieDateFormatting.dateOnly-formatted
    let colorTheme: String?
    let items: [CreateWishlistItemRequest]
}

struct CreateWishlistItemRequest: Encodable {
    let id: String
    let name: String
    let description: String
    let itemLink: String
    let price: String?
}
```

These explicitly list only the fields `POST /wishlists` accepts, rather than relying on the server's `whitelist: true` stripping of extra `WishlistItem` fields (`image`, `isPicked`, `isMostDesired`, etc.) — matching the existing convention of an explicit field list already used for `.signup`'s body in `APIRoute.asURLRequest()`. No new response DTO is needed: `POST /wishlists` and the per-item image `PATCH` both decode into the existing `WishlistResponse`/`WishlistItemResponse` (now living in `APIResponse.swift`), reusing `WishlistModel.init(response:)` / `WishlistItem.init(response:)` as-is.

### Service layer

`WishlistServiceProtocol.createWishlist` drops the `Result<>` wrapper, matching the convention already adopted for `getUserWishlists()`/`getProfile(id:)` (redundant on top of `async throws`), and returns the created `WishlistModel` directly instead of just its id string, since the API already returns the full object:

```swift
// before
func createWishlist(wishList: WishlistModel) async throws -> Result<String, Error>
// after
func createWishlist(wishList: WishlistModel) async throws -> WishlistModel
```

```swift
func createWishlist(wishList: WishlistModel) async throws -> WishlistModel {
    let request = CreateWishlistRequest(wishList)
    let created: WishlistResponse = try await apiService.send(.createWishlist(request))
    let model = WishlistModel(response: created)

    await withTaskGroup(of: Void.self) { group in
        for item in wishList.items where item.localImage != nil {
            group.addTask {
                try? await self.uploadItemImage(wishlistId: model.id, itemId: item.id, image: item.localImage!)
            }
        }
    }

    return model
}

private func uploadItemImage(wishlistId: String, itemId: String, image: UIImage) async throws {
    guard let data = image.jpegData(compressionQuality: 0.8) else { return }
    let _: WishlistItemResponse = try await apiService.send(.uploadItemImage(wishlistId: wishlistId, itemId: itemId, imageData: data))
}
```

Only items with a local `UIImage` (picked from the photo library, or downloaded via `LinkPresentationMetadataMapper`) get an image uploaded. Items whose only image source is a remote `imageUrl` string (scraped by `WebViewMetadataExtractor` from a pasted product link, with no `localImage`) are created without an image in this pass — the API has no way to accept a remote URL at creation, and re-downloading + re-uploading that image is out of scope (see Out of scope).

Image upload failures are swallowed (`try?`) — the wishlist and its items already exist server-side by the time image upload runs, so one failed image doesn't invalidate the whole creation. This mirrors the existing "one bad item doesn't fail the whole result" convention in `WishlistServiceProtocol.pairWithOwnerProfiles` (`WishlistService.swift:41-56`). Concurrency uses `withTaskGroup`, also matching that existing convention.

Every other `WishlistServiceProtocol` method is untouched — still Firestore/Supabase-backed.

### ViewModel & view changes

`CreateWishlistViewModel.saveItem()` drops its own `Result<>` wrapper and the manual pre-upload loop (image upload now happens inside `WishlistService.createWishlist`, after the wishlist exists):

```swift
func saveItem() async throws -> WishlistModel {
    guard let userId = UserDefaults.standard.string(forKey: "userid") else {
        throw NSError(domain: "UserError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
    }
    let wishList = WishlistModel(
        name: name,
        description: description,
        dueDate: dueDate,
        items: items,
        themeColor: selectedTheme?.rawValue,
        userCreateId: userId
    )
    return try await createWishListService.createWishlist(wishList: wishList)
}
```

`CreateWishListScreen`'s button-tap `Task { }` (`CreateWishListScreen.swift:69-84`) changes from a `switch result { .success/.failure }` to `do { let wishlist = try await ...; path.append(.createSuccess(wishListId: wishlist.id)) } catch { errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription }` — the same error-surfacing convention `HomeViewModel`/`ArchivedWishlistsViewModel` already use. `CreateWishlistSuccessScreen` is unchanged; it only consumes the returned `wishlistId` string.

### Error handling

A failure on the initial `POST /wishlists` call (network/timeout, `400` invalid item / too many items, `409` duplicate id — the last one practically unreachable given fresh UUIDs) fails the whole creation, surfaced via `errorMessage` on `CreateWishListScreen`. Per-item image upload failures after that point are silent (see Service layer above) — no toast or partial-failure UI in this pass.

## Alternatives considered

- **Send item images inline at creation, encoded as base64 JSON**: avoids a second network round-trip per item, but `POST /wishlists` doesn't support it — the API only accepts image bytes via multipart on the dedicated per-item endpoints. Rejected — not something the frontend can change.
- **Reuse the legacy `Endpoint`/`APIClient` multipart path (already used for avatar upload)**: less new code, but keeps two networking stacks running in parallel indefinitely. Rejected — the `APIRoute` enum is meant to be the single source of truth for every route going forward; extending it to support multipart is the more consistent long-term choice, and the actual new code is small (one computed property, one branch in `APIService.send`).
- **Fail the whole creation if any item image upload fails**: simpler mental model, but misleading — the wishlist and items already exist on the server by that point, so surfacing a hard failure would suggest nothing was created when in fact everything was, minus one image. Rejected in favor of the existing swallow-per-item-failure convention.
- **Download and re-upload remote (`imageUrl`) images from pasted links so those items get an image too**: more complete, but adds a network fetch + failure handling path for what's an edge case (only paste-link-sourced items without a `localImage` hit it); deferred.
- **Namespaced `APIRequest`/`APIResponse` enums with nested DTO types** (e.g. `APIRequest.CreateWishlist`, `APIResponse.Wishlist`): clearer grouping and avoids ever colliding with domain model names, but requires renaming every existing reference (`SignUpRequest`, `WishlistResponse`, etc.) across the codebase for a collision problem that doesn't currently exist — domain models already have distinct names (`WishlistModel`, `UserModel`) from their DTOs. Rejected in favor of flat structs grouped into two files, matching the existing precedent in `WishlistResponse.swift`.

## Out of scope

- `WishlistService.getWishlist(by:)`, `joinWishlist`, `leaveWishlist`, `deleteWishlist`, item CRUD (`updateWishlistItem`, `deleteWishlistItem`, `pickItem`, `setMostDesired`, `addWishlistItem`), `updateWishlistInfo`, `setArchived`, share/invite-code endpoints, `observeWishlist`, `observeUserWishlistIds` — all stay Firestore/Supabase-backed, tracked separately per `2026-07-25-nestjs-backend-migration-design.md`.
- Re-uploading remote (`imageUrl`-only) images from pasted links as part of creation.
- Any non-blocking UI (toast/banner) surfacing which individual item images failed to upload.
- `AuthenticateService`'s avatar upload — stays on the legacy `Endpoint`/`APIClient` multipart path, untouched.
- Production base URL / Railway deployment (per `API.md`, not yet available).
- **Known consequence, called out explicitly**: a wishlist created through this new flow now lives in Postgres, not Firestore. Per the prior list-migration slice's already-documented consequence, opening such a wishlist still routes to the Firestore-backed `WishlistDetailScreen`, whose `observeWishlist(by:)` listener never fires for a Postgres-only id — so it won't load. This was already true for any API-created wishlist before this slice (e.g. ones seeded via Swagger) and remains an accepted gap until `WishlistDetailScreen` itself migrates in a later slice.

## Testing

- Unit tests for `CreateWishlistRequest`/`CreateWishlistItemRequest` encoding.
- Unit tests for `APIRoute.asURLRequest()` covering `.createWishlist` (path/method/auth/JSON body) and `.uploadItemImage` (path/method/auth/multipart body construction, no JSON body).
- Unit tests for `WishlistService.createWishlist` against `StubAPIService`: success with no items, success with items (none having a `localImage`), success where one of several item image uploads fails (overall result still succeeds), and initial-create failure (network/decoded `APIError`) propagates.
- Unit tests for `CreateWishlistViewModel.saveItem()` against a mock `WishlistServiceProtocol`: success and thrown-error paths.
- Manual verification: with `wishie-server` running locally, create a wishlist through the 3-step UI with a mix of a locally-picked-image item, a paste-link item (remote `imageUrl`, no image expected after creation), and no items; confirm it appears correctly via `GET /wishlists` / Swagger afterward.
