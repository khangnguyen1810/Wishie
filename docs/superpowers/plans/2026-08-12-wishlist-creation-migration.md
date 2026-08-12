# Wishlist Creation API Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move `WishlistService.createWishlist` off Firestore onto the NestJS API (`POST /wishlists` + best-effort per-item image upload via `PATCH /wishlists/:wishlistId/items/:itemId`), while consolidating request/response DTOs into two files.

**Architecture:** Extend the existing `APIRoute`/`APIService` (Alamofire-based) networking layer with two new routes — a JSON `POST /wishlists` and a multipart `PATCH .../items/:itemId` — then rewrite `WishlistService.createWishlist` to call the API and upload images for items with a local `UIImage`, swallowing individual image-upload failures. `CreateWishlistViewModel`/`CreateWishListScreen` adapt to the new `async throws -> WishlistModel` signature (dropping the old `Result<>` wrapper).

**Tech Stack:** Swift, SwiftUI, Alamofire, Swift Testing (`import Testing`, `@Test`, `#expect`), `xcodebuild`.

## Global Constraints

- No new external dependencies — Alamofire is already an SPM dependency and already used by `APIRoute`/`APIService`.
- `SignUpRequest`, `WishlistResponse`, `WishlistItemResponse`, `WishlistMemberResponse`, `ProfileResponse` keep their exact struct names — only their file location changes, so no other file's references to them change.
- `WishlistServiceProtocol` conformance must stay consistent across both implementers: `WishlistService` (real) and `MockWishlistService` (test double in `WishieTests/`).
- `Route.createSuccess(wishListId: String)` (`Wishie/Models/Route.swift:13`) is unchanged.
- The project uses Xcode's file-system-synchronized groups (`PBXFileSystemSynchronizedRootGroup`) — new/deleted `.swift` files under `Wishie/` and `WishieTests/` are picked up automatically; no `.pbxproj` editing is needed.
- Test command for a single suite: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:WishieTests/<SuiteName>` (confirmed working in this environment). For the full unit test target, drop `-only-testing` or use `-only-testing:WishieTests`.
- Tests that read/write `UserDefaults.standard` at `WishieConstants.userIdKey` must be nested inside `extension UserDefaultsSharingTests { @MainActor @Suite struct ... } }` (see `WishieTests/UserDefaultsSharingTests.swift`) to avoid races with `HomeViewModelGetListWishlistTests`/`ArchivedWishlistsViewModelTests`, which already share that suite for the same reason.

---

### Task 1: Consolidate request/response DTOs into `APIRequest.swift` / `APIResponse.swift`

**Files:**
- Create: `Wishie/Models/APIRequest.swift`
- Create: `Wishie/Models/APIResponse.swift`
- Delete: `Wishie/Models/SignUpRequest.swift`
- Delete: `Wishie/Models/WishlistResponse.swift`
- Delete: `Wishie/Models/ProfileResponse.swift`

**Interfaces:**
- Consumes: nothing new — this is a pure relocation of existing types (`SignUpRequest`, `WishlistResponse`, `WishlistItemResponse`, `WishlistMemberResponse`, `ProfileResponse`).
- Produces: `Wishie/Models/APIRequest.swift` as the home for all future request DTOs (Task 2 adds `CreateWishlistRequest`/`CreateWishlistItemRequest` here); `Wishie/Models/APIResponse.swift` as the home for all future response DTOs.

This task has no new behavior, so it's verified by keeping the existing test suite green rather than by a new test.

- [ ] **Step 1: Create `Wishie/Models/APIRequest.swift` with the current contents of `SignUpRequest.swift`**

```swift
import Foundation

struct SignUpRequest {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var phone: String = ""
    var password: String = ""
    var dateOfBirth: Date = Date()
}
```

- [ ] **Step 2: Create `Wishie/Models/APIResponse.swift` with the current contents of `WishlistResponse.swift` and `ProfileResponse.swift` combined**

```swift
import Foundation

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

struct ProfileResponse: Decodable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let dateOfBirth: String?
    let avatarUrl: String?
    let interests: [String]
    let hasCompletedInterestsSetup: Bool
    let createdAt: String
}
```

- [ ] **Step 3: Delete the three old files**

```bash
rm Wishie/Models/SignUpRequest.swift Wishie/Models/WishlistResponse.swift Wishie/Models/ProfileResponse.swift
```

- [ ] **Step 4: Build to confirm nothing references the old file paths in a way that breaks compilation**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Run the full unit test target to confirm no existing behavior broke**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:WishieTests`
Expected: `** TEST SUCCEEDED **`, all suites pass (in particular `APIRouteTests`, `WishlistResponseMappingTests`, `WishlistServiceAPITests`, `AuthenticateServiceTests`, which reference the moved types).

- [ ] **Step 6: Commit**

```bash
git add Wishie/Models/APIRequest.swift Wishie/Models/APIResponse.swift
git add Wishie/Models/SignUpRequest.swift Wishie/Models/WishlistResponse.swift Wishie/Models/ProfileResponse.swift
git commit -m "refactor: consolidate request/response DTOs into APIRequest.swift/APIResponse.swift"
```

---

### Task 2: Add `CreateWishlistRequest`/`CreateWishlistItemRequest`

**Files:**
- Modify: `Wishie/Models/APIRequest.swift`
- Test: `WishieTests/APIRequestTests.swift` (new)

**Interfaces:**
- Consumes: `WishlistModel`, `WishlistItem` (`Wishie/Models/WishlistModel.swift`, `Wishie/Models/WishlistItem.swift`), `WishieDateFormatting.dateOnly` (`Wishie/Networking/WishieDateFormatting.swift`).
- Produces: `CreateWishlistRequest: Encodable` and `CreateWishlistItemRequest: Encodable`, each with a convenience initializer from the domain model (`CreateWishlistRequest.init(_:WishlistModel)`, `CreateWishlistItemRequest.init(_:WishlistItem)`). Task 3 (`APIRoute.createWishlist`) and Task 6 (`WishlistService.createWishlist`) both consume these.

- [ ] **Step 1: Write the failing test**

Create `WishieTests/APIRequestTests.swift`:

```swift
import Testing
import Foundation
@testable import Wishie

struct APIRequestTests {
    @Test func createWishlistItemRequestEncodesExpectedFields() throws {
        let item = WishlistItem(id: "i1", name: "Lego", description: "Fun set", itemLink: "https://shop.example.com", price: "19.99")
        let request = CreateWishlistItemRequest(item)

        let data = try JSONEncoder().encode(request)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["id"] as? String == "i1")
        #expect(json["name"] as? String == "Lego")
        #expect(json["description"] as? String == "Fun set")
        #expect(json["itemLink"] as? String == "https://shop.example.com")
        #expect(json["price"] as? String == "19.99")
        #expect(json["imageUrl"] == nil)
    }

    @Test func createWishlistRequestEncodesExpectedFieldsIncludingItemsAndDateOnly() throws {
        let dueDate = try #require(WishieDateFormatting.dateOnly.date(from: "2026-09-01"))
        let item = WishlistItem(id: "i1", name: "Lego", itemLink: "https://shop.example.com", price: "19.99")
        let wishlist = WishlistModel(
            id: "w1",
            name: "Birthday",
            description: "Party",
            dueDate: dueDate,
            items: [item],
            themeColor: "sunset",
            userCreateId: "u1"
        )
        let request = CreateWishlistRequest(wishlist)

        let data = try JSONEncoder().encode(request)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["id"] as? String == "w1")
        #expect(json["name"] as? String == "Birthday")
        #expect(json["description"] as? String == "Party")
        #expect(json["dueDate"] as? String == "2026-09-01")
        #expect(json["colorTheme"] as? String == "sunset")
        let items = try #require(json["items"] as? [[String: Any]])
        #expect(items.count == 1)
        #expect(items[0]["id"] as? String == "i1")
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:WishieTests/APIRequestTests`
Expected: build failure — `cannot find 'CreateWishlistItemRequest' in scope` (the type doesn't exist yet).

- [ ] **Step 3: Add the two structs to `Wishie/Models/APIRequest.swift`**

Append to the end of `Wishie/Models/APIRequest.swift`:

```swift

struct CreateWishlistItemRequest: Encodable {
    let id: String
    let name: String
    let description: String
    let itemLink: String
    let price: String?

    init(_ item: WishlistItem) {
        self.id = item.id
        self.name = item.name
        self.description = item.description
        self.itemLink = item.itemLink
        self.price = item.price
    }
}

struct CreateWishlistRequest: Encodable {
    let id: String
    let name: String
    let description: String
    let dueDate: String
    let colorTheme: String?
    let items: [CreateWishlistItemRequest]

    init(_ wishlist: WishlistModel) {
        self.id = wishlist.id
        self.name = wishlist.name
        self.description = wishlist.description
        self.dueDate = WishieDateFormatting.dateOnly.string(from: wishlist.dueDate)
        self.colorTheme = wishlist.themeColor
        self.items = wishlist.items.map(CreateWishlistItemRequest.init)
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:WishieTests/APIRequestTests`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add Wishie/Models/APIRequest.swift WishieTests/APIRequestTests.swift
git commit -m "feat: add CreateWishlistRequest/CreateWishlistItemRequest DTOs"
```

---

### Task 3: Add `APIRoute.createWishlist`

**Files:**
- Modify: `Wishie/Networking/APIRoute.swift`
- Test: `WishieTests/APIRouteTests.swift`

**Interfaces:**
- Consumes: `CreateWishlistRequest` (Task 2).
- Produces: `APIRoute.createWishlist(CreateWishlistRequest)` case, dispatched the same way as `.login`/`.signup`/`.refresh` (JSON body, via `APIService.send`). Task 6 (`WishlistService.createWishlist`) sends this route.

- [ ] **Step 1: Write the failing test**

Add to `WishieTests/APIRouteTests.swift` (inside `struct APIRouteTests`):

```swift
    @Test func createWishlistBuildsAnAuthenticatedPOSTWithTheWishlistBody() throws {
        let item = WishlistItem(id: "i1", name: "Lego", itemLink: "https://shop.example.com", price: "19.99")
        let wishlist = WishlistModel(id: "w1", name: "Birthday", dueDate: Date(), items: [item], userCreateId: "u1")
        let body = CreateWishlistRequest(wishlist)

        let request = try APIRoute.createWishlist(body).asURLRequest()

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/wishlists")
        #expect(request.value(forHTTPHeaderField: APIRoute.requiresAuthHeader) == "true")
        let httpBody = try #require(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: httpBody) as? [String: Any]
        #expect(json?["id"] as? String == "w1")
        #expect(json?["name"] as? String == "Birthday")
    }
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:WishieTests/APIRouteTests`
Expected: build failure — `type 'APIRoute' has no member 'createWishlist'`.

- [ ] **Step 3: Add the case and wire it through every switch in `Wishie/Networking/APIRoute.swift`**

Replace:
```swift
    case login(email: String, password: String)
    case signup(SignUpRequest)
    case refresh(refreshToken: String)
    case getWishlists
    case getProfile(id: String)
```
with:
```swift
    case login(email: String, password: String)
    case signup(SignUpRequest)
    case refresh(refreshToken: String)
    case getWishlists
    case getProfile(id: String)
    case createWishlist(CreateWishlistRequest)
```

Replace:
```swift
    var method: HTTPMethod {
        switch self {
        case .getWishlists, .getProfile: return .get
        case .login, .signup, .refresh: return .post
        }
    }
```
with:
```swift
    var method: HTTPMethod {
        switch self {
        case .getWishlists, .getProfile: return .get
        case .login, .signup, .refresh, .createWishlist: return .post
        }
    }
```

Replace:
```swift
    var path: String {
        switch self {
        case .login: return "/auth/login"
        case .signup: return "/auth/signup"
        case .refresh: return "/auth/refresh"
        case .getWishlists: return "/wishlists"
        case .getProfile(let id): return "/profiles/\(id)"
        }
    }
```
with:
```swift
    var path: String {
        switch self {
        case .login: return "/auth/login"
        case .signup: return "/auth/signup"
        case .refresh: return "/auth/refresh"
        case .getWishlists: return "/wishlists"
        case .getProfile(let id): return "/profiles/\(id)"
        case .createWishlist: return "/wishlists"
        }
    }
```

Replace:
```swift
    var requiresAuth: Bool {
        switch self {
        case .login, .signup, .refresh: return false
        case .getWishlists, .getProfile: return true
        }
    }
```
with:
```swift
    var requiresAuth: Bool {
        switch self {
        case .login, .signup, .refresh: return false
        case .getWishlists, .getProfile, .createWishlist: return true
        }
    }
```

Replace:
```swift
        switch self {
        case .login(let email, let password):
            return try JSONEncoding.default.encode(request, with: ["email": email, "password": password])
        case .signup(let body):
            return try JSONEncoding.default.encode(request, with: [
                "email": body.email,
                "password": body.password,
                "firstName": body.firstName,
                "lastName": body.lastName,
                "phone": body.phone,
                "dateOfBirth": WishieDateFormatting.dateOnly.string(from: body.dateOfBirth)
            ])
        case .refresh(let refreshToken):
            return try JSONEncoding.default.encode(request, with: ["refreshToken": refreshToken])
        case .getWishlists, .getProfile:
            return request
        }
    }
}
```
with:
```swift
        switch self {
        case .login(let email, let password):
            return try JSONEncoding.default.encode(request, with: ["email": email, "password": password])
        case .signup(let body):
            return try JSONEncoding.default.encode(request, with: [
                "email": body.email,
                "password": body.password,
                "firstName": body.firstName,
                "lastName": body.lastName,
                "phone": body.phone,
                "dateOfBirth": WishieDateFormatting.dateOnly.string(from: body.dateOfBirth)
            ])
        case .refresh(let refreshToken):
            return try JSONEncoding.default.encode(request, with: ["refreshToken": refreshToken])
        case .createWishlist(let body):
            request.httpBody = try JSONEncoder().encode(body)
            return request
        case .getWishlists, .getProfile:
            return request
        }
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:WishieTests/APIRouteTests`
Expected: `** TEST SUCCEEDED **`, all `APIRouteTests` tests pass (including the pre-existing ones).

- [ ] **Step 5: Commit**

```bash
git add Wishie/Networking/APIRoute.swift WishieTests/APIRouteTests.swift
git commit -m "feat: add APIRoute.createWishlist"
```

---

### Task 4: Add `APIRoute.uploadItemImage` (multipart)

**Files:**
- Modify: `Wishie/Networking/APIRoute.swift`
- Test: `WishieTests/APIRouteTests.swift`

**Interfaces:**
- Consumes: nothing new.
- Produces: `APIRoute.uploadItemImage(wishlistId: String, itemId: String, imageData: Data)` case, and a new `APIRoute.multipartFormData: ((MultipartFormData) -> Void)?` computed property (`nil` for every other case). Task 5 (`APIService.send`) reads `multipartFormData` to decide how to dispatch. Task 6 (`WishlistService`) sends this route.

- [ ] **Step 1: Write the failing tests**

Add to `WishieTests/APIRouteTests.swift`. First add `import Alamofire` under the existing imports at the top of the file (needed for `MultipartFormData`):

```swift
import Testing
import Foundation
import Alamofire
@testable import Wishie
```

Then add inside `struct APIRouteTests`:

```swift
    @Test func uploadItemImageBuildsAnAuthenticatedPATCHWithNoJSONBody() throws {
        let request = try APIRoute.uploadItemImage(wishlistId: "w1", itemId: "i1", imageData: Data([0x01])).asURLRequest()

        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.path == "/wishlists/w1/items/i1")
        #expect(request.value(forHTTPHeaderField: APIRoute.requiresAuthHeader) == "true")
        #expect(request.httpBody == nil)
    }

    @Test func uploadItemImageMultipartFormDataAppendsTheImageAsAFileField() throws {
        let imageData = Data([0xFF, 0xD8, 0xFF])
        let route = APIRoute.uploadItemImage(wishlistId: "w1", itemId: "i1", imageData: imageData)
        let form = MultipartFormData()

        route.multipartFormData?(form)
        let encoded = try form.encode()
        let encodedString = String(decoding: encoded, as: UTF8.self)

        #expect(encodedString.contains("name=\"file\""))
        #expect(encodedString.contains("filename=\"image.jpg\""))
        #expect(encodedString.contains("Content-Type: image/jpeg"))
    }

    @Test func nonUploadRoutesHaveNoMultipartFormData() {
        #expect(APIRoute.getWishlists.multipartFormData == nil)
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:WishieTests/APIRouteTests`
Expected: build failure — `type 'APIRoute' has no member 'uploadItemImage'`.

- [ ] **Step 3: Add the case, wire it through every switch, and add the `multipartFormData` property**

Replace:
```swift
    case getWishlists
    case getProfile(id: String)
    case createWishlist(CreateWishlistRequest)
```
with:
```swift
    case getWishlists
    case getProfile(id: String)
    case createWishlist(CreateWishlistRequest)
    case uploadItemImage(wishlistId: String, itemId: String, imageData: Data)
```

Replace:
```swift
    var method: HTTPMethod {
        switch self {
        case .getWishlists, .getProfile: return .get
        case .login, .signup, .refresh, .createWishlist: return .post
        }
    }
```
with:
```swift
    var method: HTTPMethod {
        switch self {
        case .getWishlists, .getProfile: return .get
        case .login, .signup, .refresh, .createWishlist: return .post
        case .uploadItemImage: return .patch
        }
    }
```

Replace:
```swift
        case .createWishlist: return "/wishlists"
        }
    }
```
with:
```swift
        case .createWishlist: return "/wishlists"
        case .uploadItemImage(let wishlistId, let itemId, _): return "/wishlists/\(wishlistId)/items/\(itemId)"
        }
    }
```

Replace:
```swift
    var requiresAuth: Bool {
        switch self {
        case .login, .signup, .refresh: return false
        case .getWishlists, .getProfile, .createWishlist: return true
        }
    }
```
with:
```swift
    var requiresAuth: Bool {
        switch self {
        case .login, .signup, .refresh: return false
        case .getWishlists, .getProfile, .createWishlist, .uploadItemImage: return true
        }
    }

    /// Non-`nil` only for multipart routes. `APIService.send` checks this to decide whether to
    /// dispatch via `session.upload(multipartFormData:with:)` instead of `session.request(_:)`.
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

Replace the whole `asURLRequest()` function:
```swift
    func asURLRequest() throws -> URLRequest {
        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if requiresAuth {
            request.setValue("true", forHTTPHeaderField: Self.requiresAuthHeader)
        }
        switch self {
        case .login(let email, let password):
            return try JSONEncoding.default.encode(request, with: ["email": email, "password": password])
        case .signup(let body):
            return try JSONEncoding.default.encode(request, with: [
                "email": body.email,
                "password": body.password,
                "firstName": body.firstName,
                "lastName": body.lastName,
                "phone": body.phone,
                "dateOfBirth": WishieDateFormatting.dateOnly.string(from: body.dateOfBirth)
            ])
        case .refresh(let refreshToken):
            return try JSONEncoding.default.encode(request, with: ["refreshToken": refreshToken])
        case .createWishlist(let body):
            request.httpBody = try JSONEncoder().encode(body)
            return request
        case .getWishlists, .getProfile:
            return request
        }
    }
}
```
with:
```swift
    func asURLRequest() throws -> URLRequest {
        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        if requiresAuth {
            request.setValue("true", forHTTPHeaderField: Self.requiresAuthHeader)
        }
        // `.uploadItemImage` has no JSON body — Alamofire sets the multipart `Content-Type`
        // (with boundary) itself when `APIService.send` encodes `multipartFormData`.
        if case .uploadItemImage = self {
            return request
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        switch self {
        case .login(let email, let password):
            return try JSONEncoding.default.encode(request, with: ["email": email, "password": password])
        case .signup(let body):
            return try JSONEncoding.default.encode(request, with: [
                "email": body.email,
                "password": body.password,
                "firstName": body.firstName,
                "lastName": body.lastName,
                "phone": body.phone,
                "dateOfBirth": WishieDateFormatting.dateOnly.string(from: body.dateOfBirth)
            ])
        case .refresh(let refreshToken):
            return try JSONEncoding.default.encode(request, with: ["refreshToken": refreshToken])
        case .createWishlist(let body):
            request.httpBody = try JSONEncoder().encode(body)
            return request
        case .getWishlists, .getProfile, .uploadItemImage:
            return request
        }
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:WishieTests/APIRouteTests`
Expected: `** TEST SUCCEEDED **`, all `APIRouteTests` tests pass.

- [ ] **Step 5: Commit**

```bash
git add Wishie/Networking/APIRoute.swift WishieTests/APIRouteTests.swift
git commit -m "feat: add APIRoute.uploadItemImage multipart route"
```

---

### Task 5: Dispatch multipart routes in `APIService.send`

**Files:**
- Modify: `Wishie/Networking/APIService.swift`
- Test: `WishieTests/APIServiceTests.swift`

**Interfaces:**
- Consumes: `APIRoute.multipartFormData` (Task 4).
- Produces: `APIService.send<T>` now transparently supports both JSON routes and multipart routes — no signature change, so `WishlistService` (Task 6) calls it exactly the same way (`try await apiService.send(route)`) for both `.createWishlist` and `.uploadItemImage`.

- [ ] **Step 1: Write the failing test**

Add to `WishieTests/APIServiceTests.swift`, inside `struct APIServiceTests` (alongside the other `@Test` methods):

```swift
    @Test func sendDispatchesMultipartRoutesAsAnUploadRequest() async throws {
        struct Sample: Decodable { let id: String }
        var capturedContentType: String?
        MockURLProtocol.requestHandler = { request in
            capturedContentType = request.value(forHTTPHeaderField: "Content-Type")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"id":"i1"}"#.utf8))
        }
        let service = APIService(configuration: makeConfiguration(), sessionStore: SessionStore(keychain: seededKeychain(accessToken: "valid-token")))

        let result: Sample = try await service.send(.uploadItemImage(wishlistId: "w1", itemId: "i1", imageData: Data([0xFF, 0xD8, 0xFF])))

        #expect(result.id == "i1")
        #expect(capturedContentType?.hasPrefix("multipart/form-data") == true)
    }
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:WishieTests/MockURLProtocolSharingTests/APIServiceTests`
Expected: the new test fails (times out or throws) because `APIService.send` currently always calls `session.request(route)`, which sends `.uploadItemImage` as a bodyless PATCH with no multipart `Content-Type` header — `capturedContentType?.hasPrefix("multipart/form-data")` is `false`.

- [ ] **Step 3: Update `send<T>` in `Wishie/Networking/APIService.swift`**

Replace:
```swift
    func send<T: Decodable>(_ route: APIRoute) async throws -> T {
        let dataResponse = await session.request(route)
            .validate()
            .serializingData()
            .response
```
with:
```swift
    func send<T: Decodable>(_ route: APIRoute) async throws -> T {
        let request: DataRequest
        if let multipartFormData = route.multipartFormData {
            request = session.upload(multipartFormData: multipartFormData, with: route)
        } else {
            request = session.request(route)
        }
        let dataResponse = await request
            .validate()
            .serializingData()
            .response
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:WishieTests/MockURLProtocolSharingTests/APIServiceTests`
Expected: `** TEST SUCCEEDED **`, all `APIServiceTests` tests pass (including the pre-existing ones — confirming the JSON-route path is unaffected).

- [ ] **Step 5: Commit**

```bash
git add Wishie/Networking/APIService.swift WishieTests/APIServiceTests.swift
git commit -m "feat: dispatch multipart APIRoutes via Alamofire upload in APIService.send"
```

---

### Task 6: Migrate `WishlistService.createWishlist` to the API

**Files:**
- Modify: `Wishie/Services/WishlistService.swift`
- Modify: `WishieTests/MockWishlistService.swift`
- Test: `WishieTests/WishlistServiceAPITests.swift`

**Interfaces:**
- Consumes: `APIRoute.createWishlist`/`.uploadItemImage` (Tasks 3–4), `APIService.send` (Task 5), `WishlistModel.init(response:)` / `WishlistItem.init(response:)` (already exist, unchanged).
- Produces: `WishlistServiceProtocol.createWishlist(wishList:) async throws -> WishlistModel` (was `async throws -> Result<String, Error>`). Task 7 (`CreateWishlistViewModel`) consumes this new signature. `MockWishlistService.createWishlistResult: Result<WishlistModel, Error>?` and `MockWishlistService.lastCreatedWishlist: WishlistModel?` are new test-double controls Task 7's tests use.

- [ ] **Step 1: Write the failing tests**

Add `import UIKit` to the top of `WishieTests/WishlistServiceAPITests.swift` (needed for the `UIImage` helper below):

```swift
import Testing
import Foundation
import UIKit
@testable import Wishie
```

Add inside `struct WishlistServiceAPITests` (alongside the existing private helpers and `@Test` methods):

```swift
    private func testImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
    }

    @Test func createWishlistSendsTheWishlistAndMapsTheResponse() async throws {
        let stub = StubAPIService()
        stub.sendResults = [sampleWishlistResponse(id: "w1")]
        let service = WishlistService(apiService: stub)
        let wishlist = WishlistModel(name: "Birthday", dueDate: Date(), userCreateId: "u1")

        let created = try await service.createWishlist(wishList: wishlist)

        #expect(created.id == "w1")
        #expect(stub.sentRoutes.count == 1)
        guard case .createWishlist(let body) = stub.sentRoutes[0] else {
            Issue.record("expected .createWishlist route")
            return
        }
        #expect(body.name == "Birthday")
    }

    @Test func createWishlistUploadsImagesForItemsThatHaveALocalImage() async throws {
        let stub = StubAPIService()
        let item = WishlistItem(id: "i1", name: "Lego", localImage: testImage())
        stub.sendResults = [
            sampleWishlistResponse(id: "w1"),
            WishlistItemResponse(id: "i1", wishlistId: "w1", name: "Lego", description: "", imageUrl: "https://x/y.jpg", isPicked: false, pickedBy: nil, itemLink: "", price: nil, isMostDesired: false)
        ]
        let service = WishlistService(apiService: stub)
        let wishlist = WishlistModel(name: "Birthday", dueDate: Date(), items: [item], userCreateId: "u1")

        let created = try await service.createWishlist(wishList: wishlist)

        #expect(created.id == "w1")
        #expect(stub.sentRoutes.count == 2)
        guard case .uploadItemImage(let wishlistId, let itemId, _) = stub.sentRoutes[1] else {
            Issue.record("expected .uploadItemImage route")
            return
        }
        #expect(wishlistId == "w1")
        #expect(itemId == "i1")
    }

    @Test func createWishlistSwallowsAFailedItemImageUpload() async throws {
        let stub = StubAPIService()
        let item = WishlistItem(id: "i1", name: "Lego", localImage: testImage())
        stub.sendResults = [
            sampleWishlistResponse(id: "w1"),
            APIError.transport("network down")
        ]
        let service = WishlistService(apiService: stub)
        let wishlist = WishlistModel(name: "Birthday", dueDate: Date(), items: [item], userCreateId: "u1")

        let created = try await service.createWishlist(wishList: wishlist)

        #expect(created.id == "w1")
    }

    @Test func createWishlistPropagatesAFailureFromTheInitialCreateCall() async throws {
        let stub = StubAPIService()
        stub.sendResults = [APIError.server(statusCode: 400, message: "Invalid item", code: nil)]
        let service = WishlistService(apiService: stub)
        let wishlist = WishlistModel(name: "Birthday", dueDate: Date(), userCreateId: "u1")

        do {
            _ = try await service.createWishlist(wishList: wishlist)
            Issue.record("expected an error to be thrown")
        } catch let error as APIError {
            #expect(error == .server(statusCode: 400, message: "Invalid item", code: nil))
        }
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:WishieTests/WishlistServiceAPITests`
Expected: build failure — `cannot convert return expression of type 'Result<String, Error>' to return type 'WishlistModel'` (the current `createWishlist` still returns the old `Result<String, Error>` and is still Firestore-backed), or a type-mismatch on `service.createWishlist(wishList:)`'s call sites in the new tests.

- [ ] **Step 3: Update `WishlistServiceProtocol` and `WishlistService.createWishlist` in `Wishie/Services/WishlistService.swift`**

Replace:
```swift
    func createWishlist(wishList: WishlistModel) async throws -> Result<String, Error>
```
with:
```swift
    func createWishlist(wishList: WishlistModel) async throws -> WishlistModel
```

Replace the entire existing `createWishlist` method body:
```swift
    func createWishlist(wishList: WishlistModel) async throws -> Result<String, Error> {
        do {
            let data : [String: Any] = [
                "id": wishList.id,
                "wishListName": wishList.name,
                "description": wishList.description,
                "userCreateId": wishList.userCreateId,
                "dueDate": Timestamp(date: wishList.dueDate),
                "colorTheme": wishList.themeColor ?? "",
                "wishListItems": wishList.items.map {
                    [
                        "id": $0.id,
                        "name": $0.name,
                        "description": $0.description,
                        "imageUrl": $0.image ?? "",
                        "isPicked": $0.isPicked,
                        "itemLink": $0.itemLink,
                        "price": $0.price ?? ""
                    ]
                },
                "members": [
                    wishList.userCreateId: "owner"
                ]
            ]
            try await db
                .collection("wishList")
                .document(wishList.id)
                .setData(data)
            
            let userWishlistData: [String: Any] = [
                "role": "owner",
                "joinedAt": Timestamp()
            ]
            
            try await db
                .collection("users")
                .document(wishList.userCreateId)
                .collection("wishlists")
                .document(wishList.id)
                .setData(userWishlistData)
            
            return .success(wishList.id)
        } catch {
            return .failure(error)
        }
    }
```
with:
```swift
    func createWishlist(wishList: WishlistModel) async throws -> WishlistModel {
        let response: WishlistResponse = try await apiService.send(.createWishlist(CreateWishlistRequest(wishList)))
        let model = WishlistModel(response: response)

        await withTaskGroup(of: Void.self) { group in
            for item in wishList.items where item.localImage != nil {
                group.addTask {
                    try? await self.uploadItemImage(wishlistId: model.id, itemId: item.id, image: item.localImage!)
                }
            }
        }

        return model
    }

    /// Best-effort — a failed upload here doesn't fail `createWishlist`, since the wishlist and
    /// its items already exist server-side by the time this runs. Mirrors the swallow-per-item
    /// convention in `WishlistServiceProtocol.pairWithOwnerProfiles` above.
    private func uploadItemImage(wishlistId: String, itemId: String, image: UIImage) async throws {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let _: WishlistItemResponse = try await apiService.send(.uploadItemImage(wishlistId: wishlistId, itemId: itemId, imageData: data))
    }
```

- [ ] **Step 4: Update `MockWishlistService.createWishlist` in `WishieTests/MockWishlistService.swift`**

Replace:
```swift
    // MARK: - Unused by these tests; minimal stub bodies.
    func createWishlist(wishList: WishlistModel) async throws -> Result<String, Error> {
        .success(wishList.id)
    }
```
with:
```swift
    // MARK: - createWishlist
    var createWishlistResult: Result<WishlistModel, Error>?
    private(set) var lastCreatedWishlist: WishlistModel?

    func createWishlist(wishList: WishlistModel) async throws -> WishlistModel {
        lastCreatedWishlist = wishList
        if let createWishlistResult {
            return try createWishlistResult.get()
        }
        return wishList
    }

    // MARK: - Unused by these tests; minimal stub bodies.
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:WishieTests/WishlistServiceAPITests`
Expected: `** TEST SUCCEEDED **`, all `WishlistServiceAPITests` tests pass.

- [ ] **Step 6: Run the full unit test target to confirm the `WishlistServiceProtocol` signature change didn't break other conformers/callers**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:WishieTests`
Expected: build failure only in `Wishie/Screens/CreateList/CreateWishlistViewModel.swift` and `Wishie/Screens/CreateList/CreateWishListScreen.swift` (both still call the old signature) — this is expected and fixed in Task 7. If anything else fails to build, investigate before proceeding.

- [ ] **Step 7: Commit**

```bash
git add Wishie/Services/WishlistService.swift WishieTests/MockWishlistService.swift WishieTests/WishlistServiceAPITests.swift
git commit -m "feat: migrate WishlistService.createWishlist to POST /wishlists + per-item image upload"
```

---

### Task 7: Update `CreateWishlistViewModel` and `CreateWishListScreen`

**Files:**
- Modify: `Wishie/Screens/CreateList/CreateWishlistViewModel.swift`
- Modify: `Wishie/Screens/CreateList/CreateWishListScreen.swift`
- Test: `WishieTests/CreateWishlistViewModelTests.swift` (new)

**Interfaces:**
- Consumes: `WishlistServiceProtocol.createWishlist(wishList:) async throws -> WishlistModel` (Task 6), `MockWishlistService.createWishlistResult`/`lastCreatedWishlist` (Task 6), `APIError.errorDescription` (existing), `WishieConstants.userIdKey` (existing, `Wishie/Constants/WishieConstants.swift:9`).
- Produces: `CreateWishlistViewModel.saveItem() async throws -> WishlistModel` (was `async -> Result<String, Error>`). Nothing downstream of this task consumes it further — it's the top of the call chain for this feature.

- [ ] **Step 1: Write the failing tests**

Create `WishieTests/CreateWishlistViewModelTests.swift`. This nests inside `UserDefaultsSharingTests` because it mutates `UserDefaults.standard` at `WishieConstants.userIdKey`, same as `HomeViewModelGetListWishlistTests`/`ArchivedWishlistsViewModelTests` — see the note in `WishieTests/UserDefaultsSharingTests.swift`.

```swift
// WishieTests/CreateWishlistViewModelTests.swift
import Testing
import Foundation
@testable import Wishie

extension UserDefaultsSharingTests {
    @MainActor
    @Suite
    struct CreateWishlistViewModelTests {
        @Test func saveItemReturnsTheCreatedWishlistOnSuccess() async throws {
            UserDefaults.standard.set("u1", forKey: WishieConstants.userIdKey)
            defer { UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey) }
            let mockService = MockWishlistService()
            let created = WishlistModel(id: "w1", name: "Birthday", dueDate: Date(), userCreateId: "u1")
            mockService.createWishlistResult = .success(created)
            let viewModel = CreateWishlistViewModel(createWishListService: mockService)
            viewModel.name = "Birthday"

            let result = try await viewModel.saveItem()

            #expect(result.id == "w1")
            #expect(mockService.lastCreatedWishlist?.name == "Birthday")
        }

        @Test func saveItemThrowsWhenTheServiceFails() async throws {
            UserDefaults.standard.set("u1", forKey: WishieConstants.userIdKey)
            defer { UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey) }
            let mockService = MockWishlistService()
            mockService.createWishlistResult = .failure(APIError.transport("no network"))
            let viewModel = CreateWishlistViewModel(createWishListService: mockService)
            viewModel.name = "Birthday"

            do {
                _ = try await viewModel.saveItem()
                Issue.record("expected an error to be thrown")
            } catch let error as APIError {
                #expect(error == .transport("no network"))
            }
        }

        @Test func saveItemThrowsWhenNoUserIsLoggedIn() async throws {
            UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey)
            let mockService = MockWishlistService()
            let viewModel = CreateWishlistViewModel(createWishListService: mockService)
            viewModel.name = "Birthday"

            do {
                _ = try await viewModel.saveItem()
                Issue.record("expected an error to be thrown")
            } catch {
                #expect(mockService.lastCreatedWishlist == nil)
            }
        }
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:WishieTests/UserDefaultsSharingTests/CreateWishlistViewModelTests`
Expected: build failure — `cannot convert return expression of type 'Result<String, Error>' to return type 'WishlistModel'` / `value of optional type 'Result<String, Error>?' must be unwrapped` around `CreateWishlistViewModel.saveItem()`, since the view model still has the old signature.

- [ ] **Step 3: Update `Wishie/Screens/CreateList/CreateWishlistViewModel.swift`**

Replace:
```swift
    func saveItem() async -> Result<String, Error>{
        do {
            guard let userId = UserDefaults.standard.string(forKey: "userid") else {
                return .failure(NSError(
                    domain: "UserError",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "User not logged in"]
                ))
            }
            for index in items.indices {
                guard let image = items[index].localImage else { continue }
                let imageUrl = try await createWishListService.upload(image: image, fileName: UUID().uuidString)
                items[index].image = imageUrl
                items[index].localImage = nil
            }
            let wishList =  WishlistModel(
                name: name,
                description: description,
                dueDate: dueDate,
                items: items,
                themeColor: selectedTheme?.rawValue,
                userCreateId: userId)
            return try await createWishListService.createWishlist(wishList: wishList)
        } catch {
            return .failure(error)
        }
    }
```
with:
```swift
    func saveItem() async throws -> WishlistModel {
        guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else {
            throw NSError(
                domain: "UserError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "User not logged in"]
            )
        }
        let wishList = WishlistModel(
            name: name,
            description: description,
            dueDate: dueDate,
            items: items,
            themeColor: selectedTheme?.rawValue,
            userCreateId: userId)
        return try await createWishListService.createWishlist(wishList: wishList)
    }
```

- [ ] **Step 4: Update the button action in `Wishie/Screens/CreateList/CreateWishListScreen.swift`**

Replace:
```swift
                                Task {
                                    creating = true
                                    let result = await createWishlistViewModel.saveItem()
                                    switch result {
                                    case .success(let id):
                                        creating = false
                                        path.append(
                                            Route.createSuccess(
                                                wishListId: id
                                            )
                                        )
                                    case .failure(let failure):
                                        creating = false
                                        errorMessage = failure.localizedDescription
                                    }
                                }
```
with:
```swift
                                Task {
                                    creating = true
                                    do {
                                        let wishlist = try await createWishlistViewModel.saveItem()
                                        creating = false
                                        path.append(
                                            Route.createSuccess(
                                                wishListId: wishlist.id
                                            )
                                        )
                                    } catch {
                                        creating = false
                                        errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                                    }
                                }
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:WishieTests/UserDefaultsSharingTests/CreateWishlistViewModelTests`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 6: Run the full unit test target**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:WishieTests`
Expected: `** TEST SUCCEEDED **`, every suite passes — this confirms the whole feature builds and the rest of the app is unaffected.

- [ ] **Step 7: Commit**

```bash
git add Wishie/Screens/CreateList/CreateWishlistViewModel.swift Wishie/Screens/CreateList/CreateWishListScreen.swift WishieTests/CreateWishlistViewModelTests.swift
git commit -m "feat: create wishlists via the API from CreateWishlistViewModel"
```

---

### Task 8: Manual verification against a local `wishie-server`

**Files:** none — this is a manual QA pass, no code changes.

**Interfaces:**
- Consumes: the full feature built in Tasks 1–7, plus `wishie-server` running locally per `API.md` (`npm run start:dev`, port `3000`).

- [ ] **Step 1: Start the backend**

In the `wishie-server` checkout: `npm run start:dev`. Confirm it's up: `curl http://localhost:3000/health` should return `{"status":"ok"}`.

- [ ] **Step 2: Run the app in the iOS Simulator**

Build and run the `Wishie` scheme in Xcode on any simulator (simulator traffic to `http://localhost:3000` works out of the box per `API.md`'s networking table — no `Info.plist` changes needed for the simulator). Log in with a test account.

- [ ] **Step 3: Create a wishlist with a mix of item types**

Go through the 3-step create flow:
- Page 1: enter a name, description, due date.
- Page 2: add at least one item with a photo picked from the simulator's photo library (a local image), and at least one item pasted from a product link (exercises the remote-`imageUrl`-only path, which should end up with no image after creation).
- Page 3: pick a color theme.
- Tap "Create".

Expected: the app navigates to `CreateWishlistSuccessScreen` ("Success!") without an error banner.

- [ ] **Step 4: Verify the created data via Swagger**

Open `http://localhost:3000/api-docs`, authenticate (or use `curl` with the bearer token logged during sign-in), and call `GET /wishlists`. Confirm:
- The new wishlist appears with the correct `name`/`description`/`dueDate`/`colorTheme`.
- The photo-library item has a populated `imageUrl`.
- The pasted-link item has `imageUrl: null` (expected, per Task 6/Out of scope in the design doc).

- [ ] **Step 5: Spot-check the failure path**

Stop the local server (`Ctrl-C`), attempt to create another wishlist, and confirm the "Create" button surfaces an error message (from `APIError.errorDescription`, e.g. a transport/connection error) instead of silently doing nothing or crashing. Restart the server afterward if continuing manual testing.

No commit for this task — it's verification only. If any step surfaces a bug, fix it as a follow-up task (write a failing test reproducing it, then fix) before considering the feature done.

---

## Self-Review Notes

- **Spec coverage:** networking multipart support (Tasks 4–5), file organization (Task 1), request/response DTOs (Task 2), service layer + swallow-per-item-failure (Task 6), ViewModel/view signature change + error surfacing (Task 7), manual verification (Task 8) — every section of `docs/superpowers/specs/2026-08-12-wishlist-creation-migration-design.md` has a corresponding task.
- **Placeholder scan:** no TBDs; every step shows complete code, not descriptions of code.
- **Type consistency:** `createWishlist(wishList:) async throws -> WishlistModel` is identical across the protocol (Task 6), `WishlistService` (Task 6), `MockWishlistService` (Task 6), and its caller `CreateWishlistViewModel.saveItem()` (Task 7). `CreateWishlistRequest`/`CreateWishlistItemRequest` (Task 2) are used with matching names in `APIRoute.createWishlist` (Task 3) and `WishlistService.createWishlist` (Task 6).
