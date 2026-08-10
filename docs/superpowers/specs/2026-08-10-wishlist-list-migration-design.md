# Wishlist List (Owned vs. Joined) — API Migration — Design

## Context

Today the Home screen (`HomeViewModel`) and the Archived screen (`ArchivedWishlistsViewModel`) both call `WishlistService.getUserWishlists()`, which reads Firestore (`users/{uid}/wishlists` for membership, then one Firestore read per wishlist for its data and owner doc) and returns `[(WishlistModel, UserModel)]`. Callers filter this list locally by role — `members[userId] == .owner` vs. `.member` — to produce "My list" / "Friend's list" on Home, and owner-only archived wishlists on the Archived screen. Home additionally keeps this fresh via Firestore snapshot listeners (`observeUserWishlistIds`, `observeWishlist(by:)`).

A NestJS backend (`wishie-server`, documented in `API.md`) now exists with a working `GET /wishlists` endpoint: it lists every wishlist the caller belongs to (owner or member), each with `members` (`{wishlistId, userId, role, joinedAt}[]`) and `items` included, newest first. There is no separate "owned" vs. "joined" endpoint, no realtime channel (API.md: "clients are responsible for refetching"), and no owner-profile data bundled inline — only `ownerId`.

An iOS networking layer for the previous slice (`APIClient`, `SessionStore`, `APIConfig`, `Endpoint`, `APIError`, `WishieDateFormatting`) was built and code-reviewed on a separate, unmerged branch (`origin/worktree-firebase-auth-to-api-migration`), migrating `AuthenticateService` off Firebase (`2026-08-07-firebase-auth-to-api-migration-design.md`) on top of a hand-rolled `URLSession` client with a string-literal-path `Endpoint` struct. For this slice, the request-dispatch mechanism changes: routes are defined as a single `URLRequestConvertible` enum and dispatched via Alamofire, following an existing pattern from a prior project (see Alternatives considered below), instead of extending that string-literal `Endpoint` approach. `SessionStore`/`AuthSession`/`APIError`/`APIConfig`/`WishieDateFormatting` are transport-agnostic value types and are still reused as-is from that branch; only the `APIClient`/`Endpoint` pair is superseded (for this slice's routes — `AuthenticateService` itself keeps using them untouched, see Out of scope).

`WishlistService`'s other responsibilities — creating wishlists, wishlist detail, item CRUD, join/leave, archive/share, and the Firestore realtime listeners `WishlistDetailScreen` depends on — are out of scope for this pass, tracked separately (`2026-07-25-nestjs-backend-migration-design.md`). `POST /wishlists` (create) stays Firestore-backed for now, so this list will show real data only once wishlists exist in Postgres — in practice, seeded via `POST /wishlists`/`POST /wishlists/join/:code` directly (e.g. through Swagger) until wishlist creation itself migrates in a later slice.

## Goal

Replace `getUserWishlists()`'s Firestore internals with a call to `GET /wishlists`, preserving the existing owned/joined split behavior on Home and the owner-only filter on Archived, with minimal changes to the view layer.

## Approach

### Prerequisite: merge the session/error primitives

`origin/worktree-firebase-auth-to-api-migration` is merged into `epic/mirgrate-from-firebase-to-api` before this work starts, bringing in `Wishie/Networking/` (`SessionStore`, `APIConfig`, `APIError`, `WishieDateFormatting`, `AuthSession`) and the already-migrated `AuthenticateService`, unchanged. Its `APIClient`/`Endpoint` pair is not extended further — this slice's routes go through the new Alamofire router instead (below).

### Networking & routing (Alamofire + enum router)

Alamofire is added as an SPM dependency. `Wishie/Networking/APIRoute.swift` defines a single enum, `APIRoute: URLRequestConvertible`, following the case-per-endpoint pattern used elsewhere (`method`/`path`/`parameters` computed properties, `asURLRequest()` building the request):

```swift
enum APIRoute: URLRequestConvertible {
    case login(email: String, password: String)
    case signup(SignUpRequest)
    case refresh(refreshToken: String)
    case getWishlists
    case getProfile(id: String)

    private var method: HTTPMethod {
        switch self {
        case .getWishlists, .getProfile: return .get
        case .login, .signup, .refresh: return .post
        }
    }

    private var path: String {
        switch self {
        case .login: return "auth/login"
        case .signup: return "auth/signup"
        case .refresh: return "auth/refresh"
        case .getWishlists: return "wishlists"
        case .getProfile(let id): return "profiles/\(id)"
        }
    }

    private var requiresAuth: Bool {
        switch self {
        case .login, .signup, .refresh: return false
        case .getWishlists, .getProfile: return true
        }
    }

    func asURLRequest() throws -> URLRequest {
        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if requiresAuth, let token = await SessionStore.shared.current()?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        switch self {
        case .login(let email, let password):
            return try JSONEncoding.default.encode(request, with: ["email": email, "password": password])
        case .signup(let body):
            request.httpBody = try JSONEncoder().encode(body)
            return request
        case .refresh(let refreshToken):
            return try JSONEncoding.default.encode(request, with: ["refreshToken": refreshToken])
        case .getWishlists, .getProfile:
            return request
        }
    }
}
```

(`asURLRequest()` isn't actually `async` in Alamofire's `URLRequestConvertible` — the real implementation resolves the token via a synchronous cached read or an `AF.RequestAdapter` step instead; exact mechanics are an implementation-plan detail, not a design one.)

Only `.getWishlists` and `.getProfile(id:)` are called by anything in this slice. `.login`/`.signup` are defined now — at your request, so the route enum is the single source of truth for every path from the start — but stay unused; `AuthenticateService` keeps calling `/auth/login`/`/auth/signup` through its existing `APIClient`/`Endpoint` implementation from the other branch, untouched. `.refresh` **is** actively used (see below), unlike `.login`/`.signup`.

A small `APIService` wraps dispatch and decoding:
```swift
protocol APIServiceProtocol {
    func send<T: Decodable>(_ route: APIRoute) async throws -> T
}
```
implemented via `AF.request(route).validate().serializingDecodable(T.self).value`, decoding Alamofire/server errors into the existing `APIError` (reusing `APIError.decodeServerError(data:statusCode:)` from the other branch). A custom `RequestInterceptor` (`retry(_:for:dueTo:completion:)`) detects a `401`, calls `SessionStore.refreshedSession { refreshToken in try await apiService.send(.refresh(refreshToken: refreshToken)) }`, and signals Alamofire to retry once — the Alamofire-native equivalent of the old `APIClient`'s hand-rolled `executeWithRefresh`.

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

`WishlistServiceProtocol` gains two methods and drops the `Result<>` wrapper on `getUserWishlists()` (matching the calling convention `AuthenticateService` already adopted — redundant on top of `async throws`):

```swift
// before
func getUserWishlists() async throws -> Result<[(WishlistModel, UserModel)], Error>
// after
func getUserWishlists() async throws -> [WishlistModel]
func getProfile(id: String) async throws -> UserModel   // new
```

`WishlistService` gains an injected `apiService: APIServiceProtocol` (default `APIService()`):

```swift
func getUserWishlists() async throws -> [WishlistModel] {
    let responses: [WishlistResponse] = try await apiService.send(.getWishlists)
    return responses.map(WishlistModel.init(response:))
}

func getProfile(id: String) async throws -> UserModel {
    let response: ProfileResponse = try await apiService.send(.getProfile(id: id))
    return UserModel(profile: response)
}
```

(`ProfileResponse` and `UserModel.init(profile:)` are reused as-is from the other branch.)

Every other `WishlistService` method (`createWishlist`, `getWishlist(by:)`, `pickItem`, `joinWishlist`, item CRUD, `observeWishlist`, `observeUserWishlistIds`, etc.) is untouched — still Firestore-backed.

Pairing a wishlist with its owner's `UserModel` (for `HomeItemViewCell`'s avatar/name) moves out of the service and into the ViewModel layer, since the API no longer bundles a profile per wishlist. Every distinct `ownerId` appearing in the fetched list — including the current user's own wishlists, since `GET /profiles/:id` works for any id, not just other users — is resolved via `service.getProfile(id:)`, cached in a `[String: UserModel]` dictionary keyed by id so repeated owners across several wishlists only fetch once, resolved concurrently via `withThrowingTaskGroup`. This drops the need for a separate `AuthenticateServiceProtocol` dependency or a "self" special case — `HomeViewModel`/`ArchivedWishlistsViewModel` only depend on `WishlistServiceProtocol`.

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

`APIError` (thrown by `APIService`, decoded the same way the other branch's `APIClient` already does) surfaces through the existing `errorMessage: String` published property on both ViewModels, using its `errorDescription` the same way `AuthViewModel` already does — no new UI needed.

## Alternatives considered

- **Keep `getUserWishlists()` Firestore-backed, add a new API-backed method under a different name**: would leave Home and Archived reading two different backends simultaneously, and doesn't match the "no production data, single direction" nature of this migration. Rejected — the shared method itself is migrated instead, so Home and Archived move together.
- **Extend the other branch's `Endpoint`/`APIClient` (string-literal paths) instead of adding Alamofire**: avoids a new dependency and keeps one request-dispatch mechanism for the whole app. Rejected per explicit direction — a single enum-based `URLRequestConvertible` router (`APIRoute`), following an established pattern from prior work, is preferred for this and future slices; `AuthenticateService` keeps its existing implementation rather than being rewritten in the same pass.
- **Backend returns owner profile inline in `GET /wishlists`**: would remove the need for per-owner `GET /profiles/:id` calls, but requires a backend change; this migration is scoped to the frontend against the documented API surface. Rejected for this pass.
- **Skip owner-profile resolution for "Friend's list", show a placeholder**: fewer network calls, but silently degrades the existing card UI (avatar/name) for the tab where it matters most. Rejected in favor of real profile data, deduped and fetched concurrently.

## Out of scope

- `WishlistService.createWishlist`, `getWishlist(by:)`, item CRUD, `joinWishlist`, `leaveWishlist`, `deleteWishlist`, `setArchived`, share/invite-code endpoints, and `observeWishlist`/`observeUserWishlistIds` — all stay Firestore-backed.
- `WishlistDetailScreen` and its realtime updates.
- `AuthenticateService`'s actual request dispatch — stays on the other branch's `APIClient`/`Endpoint`. `.login`/`.signup` exist on `APIRoute` as unused placeholders only; wiring `AuthenticateService` onto the Alamofire router is a future slice.
- Any backend change (e.g. bundling owner profile into `GET /wishlists`).
- Production base URL / Railway deployment.

## Testing

- Unit tests for `WishlistModel.init(response:)` / `WishlistItem.init(response:)`, covering the `members[]` → role-dict folding and date parsing.
- Unit tests for `APIRoute.asURLRequest()`, covering path/method/auth-header construction for `.getWishlists` and `.getProfile(id:)`.
- Unit tests for `WishlistService.getUserWishlists()` / `getProfile(id:)` against a mocked `APIServiceProtocol`, covering success and a decoded server error.
- Unit tests for `HomeViewModel.getListWishlist()` and `ArchivedWishlistsViewModel.loadArchivedWishlists()` against a mocked `WishlistServiceProtocol`: correct owner/joined split, archived filtering, profile caching (same `ownerId` across multiple wishlists → `getProfile(id:)` called once), and the error path.
- Manual verification: with `wishie-server` running locally, seed wishlists via Swagger (`POST /wishlists`, `POST /wishlists/join/:code`) for one owned and one joined case, and confirm Home's "My list"/"Friend's list" tabs and the Archived screen show the right split and owner names/avatars.
