# Wishlist List (Owned vs. Joined) — API Migration — Design

## Context

Today the Home screen (`HomeViewModel`) and the Archived screen (`ArchivedWishlistsViewModel`) both call `WishlistService.getUserWishlists()`, which reads Firestore (`users/{uid}/wishlists` for membership, then one Firestore read per wishlist for its data and owner doc) and returns `[(WishlistModel, UserModel)]`. Callers filter this list locally by role — `members[userId] == .owner` vs. `.member` — to produce "My list" / "Friend's list" on Home, and owner-only archived wishlists on the Archived screen. Home additionally keeps this fresh via Firestore snapshot listeners (`observeUserWishlistIds`, `observeWishlist(by:)`).

A NestJS backend (`wishie-server`, documented in `API.md`) now exists with a working `GET /wishlists` endpoint: it lists every wishlist the caller belongs to (owner or member), each with `members` (`{wishlistId, userId, role, joinedAt}[]`) and `items` included, newest first. There is no separate "owned" vs. "joined" endpoint, no realtime channel (API.md: "clients are responsible for refetching"), and no owner-profile data bundled inline — only `ownerId`.

The iOS networking layer this depends on (`APIClient`, `SessionStore`, `APIConfig`, `Endpoint`, `APIError`, `WishieDateFormatting`) doesn't exist on `epic/mirgrate-from-firebase-to-api` yet — it was built and code-reviewed on a separate, unmerged branch (`origin/worktree-firebase-auth-to-api-migration`) as part of migrating `AuthenticateService` off Firebase (`2026-08-07-firebase-auth-to-api-migration-design.md`). That branch also already provides `AuthenticateService.getUserInfo(by:)`, mapped to `GET /profiles/:id`.

`WishlistService`'s other responsibilities — creating wishlists, wishlist detail, item CRUD, join/leave, archive/share, and the Firestore realtime listeners `WishlistDetailScreen` depends on — are out of scope for this pass, tracked separately (`2026-07-25-nestjs-backend-migration-design.md`). `POST /wishlists` (create) stays Firestore-backed for now, so this list will show real data only once wishlists exist in Postgres — in practice, seeded via `POST /wishlists`/`POST /wishlists/join/:code` directly (e.g. through Swagger) until wishlist creation itself migrates in a later slice.

## Goal

Replace `getUserWishlists()`'s Firestore internals with a call to `GET /wishlists`, preserving the existing owned/joined split behavior on Home and the owner-only filter on Archived, with minimal changes to the view layer.

## Approach

### Prerequisite: merge the networking layer

`origin/worktree-firebase-auth-to-api-migration` is merged into `epic/mirgrate-from-firebase-to-api` before this work starts, bringing in `Wishie/Networking/` (`APIClient`, `SessionStore`, `APIConfig`, `Endpoint`, `APIError`, `WishieDateFormatting`) and the already-migrated `AuthenticateService` (including `getUserInfo(by:)`), rather than re-implementing any of it.

### Data model & mapping (additive)

New DTOs (`Wishie/Models/WishlistResponse.swift`) decode `GET /wishlists`'s JSON shape directly:

```swift
struct WishlistMemberResponse: Decodable {
    let wishlistId: String
    let userId: String
    let role: String   // "owner" | "member"
    let joinedAt: String
}

struct WishlistItemResponse: Decodable {
    let id: String
    let wishlistId: String
    let name: String
    let description: String
    let imageUrl: String?
    let isPicked: Bool
    let pickedBy: String?
    let itemLink: String
    let price: String?
    let isMostDesired: Bool
}

struct WishlistResponse: Decodable {
    let id: String
    let name: String
    let description: String
    let ownerId: String
    let dueDate: String
    let colorTheme: String?
    let isArchived: Bool
    let createdAt: String
    let members: [WishlistMemberResponse]?
    let items: [WishlistItemResponse]?
}
```

`WishlistModel` and `WishlistItem` each gain a new `init(response:)`, alongside (not replacing) their existing Firestore `init(dictionary:)` — same pattern as `UserModel.init(profile:)` added during the auth migration:

- `WishlistModel.init(response:)`: `dueDate`/`createdAt` parsed via `WishieDateFormatting.parseServerDate`; `members` array folded into the existing `[String: WishlistRole]` dict so `isOwner()`/`isUserJoined()` (still used by the Firestore-backed `WishlistDetailScreen`) keep working unchanged; `userCreateId` populated from `ownerId`; `items` mapped via `WishlistItem.init(response:)`.
- `WishlistItem.init(response:)`: direct field mapping (`imageUrl` → `image`, `pickedBy` → `pickedUserId`, etc.), matching the existing `init(dictionary:)` field semantics.

### Service layer

`WishlistServiceProtocol.getUserWishlists()` drops its `Result<>` wrapper, matching the calling convention `AuthenticateService` already adopted (redundant on top of `async throws`):

```swift
// before
func getUserWishlists() async throws -> Result<[(WishlistModel, UserModel)], Error>
// after
func getUserWishlists() async throws -> [WishlistModel]
```

`WishlistService` gains an injected `apiClient: APIClientProtocol` (default `APIClient()`):

```swift
func getUserWishlists() async throws -> [WishlistModel] {
    let responses: [WishlistResponse] = try await apiClient.send(.get("/wishlists"))
    return responses.map(WishlistModel.init(response:))
}
```

Every other `WishlistService` method (`createWishlist`, `getWishlist(by:)`, `pickItem`, `joinWishlist`, item CRUD, `observeWishlist`, `observeUserWishlistIds`, etc.) is untouched — still Firestore-backed.

Pairing a wishlist with its owner's `UserModel` (for `HomeItemViewCell`'s avatar/name) moves out of the service and into the ViewModel layer, since the API no longer bundles a profile per wishlist:

- if `ownerId == currentUserId` → reuse the already-loaded self profile (`AuthenticateService.getUserInfo()`, called once)
- else → `AuthenticateService.getUserInfo(by: ownerId)`, results cached in a `[String: UserModel]` dictionary keyed by id so repeated owners across several wishlists only fetch once; distinct owners resolved concurrently via `withThrowingTaskGroup`

This helper is shared by `HomeViewModel` and `ArchivedWishlistsViewModel`, both of which gain an injected `authService: AuthenticateServiceProtocol` (default `AuthenticateService()`).

### ViewModel changes

`HomeViewModel.getListWishlist()` replaces both today's `getListWishlist()` and `refreshWishlists()` (identical once there's no listener-driven refresh path):

```swift
func getListWishlist() async {
    guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else { return }
    isGettingList = true
    defer { isGettingList = false }
    do {
        let wishlists = try await service.getUserWishlists().filter { !$0.isArchived }
        let owned = wishlists.filter { $0.members[userId] == .owner }
        let joined = wishlists.filter { $0.members[userId] == .member }
        async let ownedPairs = pair(owned, currentUserId: userId)
        async let joinedPairs = pair(joined, currentUserId: userId)
        (myWishlists, myFriendWishlists) = try await (ownedPairs, joinedPairs)
    } catch {
        errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
    }
}
```

`ArchivedWishlistsViewModel.loadArchivedWishlists()` follows the same shape, filtering `members[userId] == .owner && isArchived` and pairing every result with the self profile only (no per-item network calls needed, since archived wishlists here are always self-owned).

`MockWishlistService` (`WishieTests/MockWishlistService.swift`) updates `getUserWishlists()`'s return type to match the protocol.

### Realtime removal

`HomeViewModel.startObservingWishlists()`, `setWishlistListeners(wishlistIds:)`, the `userWishlistsListener`/`wishlistListeners` properties, and their `deinit` cleanup are deleted — they're Firestore-only concepts with no equivalent for a REST list, and would otherwise be dead code once nothing calls them. `HomeView.swift`'s `.task` changes from calling `homeViewModel.startObservingWishlists()` to calling `await homeViewModel.getListWishlist()` directly. The existing `.refreshable { await homeViewModel.getListWishlist() }` pull-to-refresh is unchanged and becomes the primary way to pick up changes made by other members, per API.md's "no realtime channel" guidance.

`WishlistDetailScreen`'s own Firestore listener (`observeWishlist(by:)`) is untouched — out of scope.

### Error handling

`APIError` (thrown by `APIClient`) surfaces through the existing `errorMessage: String` published property on both ViewModels, using its `errorDescription` the same way `AuthViewModel` already does — no new UI needed.

## Alternatives considered

- **Keep `getUserWishlists()` Firestore-backed, add a new API-backed method under a different name**: would leave Home and Archived reading two different backends simultaneously, and doesn't match the "no production data, single direction" nature of this migration. Rejected — the shared method itself is migrated instead, so Home and Archived move together.
- **Backend returns owner profile inline in `GET /wishlists`**: would remove the need for per-owner `GET /profiles/:id` calls, but requires a backend change; this migration is scoped to the frontend against the documented API surface. Rejected for this pass.
- **Skip owner-profile resolution for "Friend's list", show a placeholder**: fewer network calls, but silently degrades the existing card UI (avatar/name) for the tab where it matters most. Rejected in favor of real profile data, deduped and fetched concurrently.

## Out of scope

- `WishlistService.createWishlist`, `getWishlist(by:)`, item CRUD, `joinWishlist`, `leaveWishlist`, `deleteWishlist`, `setArchived`, share/invite-code endpoints, and `observeWishlist`/`observeUserWishlistIds` — all stay Firestore-backed.
- `WishlistDetailScreen` and its realtime updates.
- Any backend change (e.g. bundling owner profile into `GET /wishlists`).
- Production base URL / Railway deployment.

## Testing

- Unit tests for `WishlistModel.init(response:)` / `WishlistItem.init(response:)`, covering the `members[]` → role-dict folding and date parsing.
- Unit tests for `WishlistService.getUserWishlists()` against a mocked `APIClientProtocol`, covering success and a decoded server error.
- Unit tests for `HomeViewModel.getListWishlist()` and `ArchivedWishlistsViewModel.loadArchivedWishlists()` against mocked `WishlistServiceProtocol`/`AuthenticateServiceProtocol`: correct owner/joined split, archived filtering, profile caching (same `ownerId` across multiple wishlists → `getUserInfo(by:)` called once), and the error path.
- Manual verification: with `wishie-server` running locally, seed wishlists via Swagger (`POST /wishlists`, `POST /wishlists/join/:code`) for one owned and one joined case, and confirm Home's "My list"/"Friend's list" tabs and the Archived screen show the right split and owner names/avatars.
