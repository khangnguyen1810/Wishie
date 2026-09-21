# Wishlist List (Owned vs. Joined) — API Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `WishlistService.getUserWishlists()`'s Firestore internals with a call to `GET /wishlists` (via a new Alamofire-based `APIRoute`/`APIService`), so Home's "My list"/"Friend's list" split and the Archived screen read from the Wishie API instead of Firestore.

**Architecture:** A new `APIRoute` enum (`URLRequestConvertible`) defines routes, dispatched through a new `APIService` (wraps an `Alamofire.Session` with a custom `WishieRequestInterceptor` for bearer-token attachment and 401-refresh-retry, reusing the existing `SessionStore`/`APIError`/`APIConfig`). `WishlistService` gains `getUserWishlists()` (rewritten) and `getProfile(id:)` (new) backed by this stack; a `WishlistServiceProtocol` extension (`pairWithOwnerProfiles`) resolves each wishlist's owner profile, deduped and fetched concurrently. `HomeViewModel` and `ArchivedWishlistsViewModel` are rewritten to use this and drop their Firestore realtime-listener code, relying on task-on-appear + existing pull-to-refresh instead.

**Tech Stack:** Swift, SwiftUI, Alamofire (new SPM dependency), Swift Testing (`import Testing`, `@Test`, `#expect` — not XCTest), Xcode 26.

## Global Constraints

- Testing framework is Swift Testing (`import Testing`, `struct ...Tests { @Test func ... }`, `#expect(...)`, `Issue.record(...)`) — every existing test file in `WishieTests/` uses this, not XCTest. Match it exactly.
- `WishieTests` runs hosted inside the `Wishie.app` process (see `TEST_HOST` in the Xcode project) — it does not need its own Alamofire package linkage; only the `Wishie` app target does.
- `AuthenticateService`'s actual request dispatch is **not** touched by this plan — it keeps using the existing `APIClient`/`Endpoint`/`SessionStore` from `Wishie/Networking/`. `APIRoute.login`/`.signup` are defined but never called by any code in this plan.
- Every other `WishlistService` method (`createWishlist`, `getWishlist(by:)`, item CRUD, `joinWishlist`, `leaveWishlist`, `deleteWishlist`, `setArchived`, `observeWishlist`, `observeUserWishlistIds`) stays Firestore-backed, untouched.
- `WishlistDetailScreen` and its Firestore listener are untouched.
- Alamofire version floor: `5.9.0`, `upToNextMajorVersion` (matches the `requirement` style already used for `GoogleSignIn-iOS`/`SDWebImageSwiftUI` in `Wishie.xcodeproj/project.pbxproj`).
- Spec: `docs/superpowers/specs/2026-08-10-wishlist-list-migration-design.md`.

---

### Task 1: Add Alamofire as a Swift Package dependency

**Files:**
- Modify: `Wishie.xcodeproj/project.pbxproj` (via script, not hand-edited)
- Create (temporary, deleted after use): `/tmp/add_alamofire.rb`

**Interfaces:**
- Consumes: nothing
- Produces: `import Alamofire` becomes available to any file in the `Wishie` app target (not `WishieTests`/`WishieUITests`)

- [ ] **Step 1: Confirm the `xcodeproj` gem is available**

Run: `gem list xcodeproj -i`
Expected: `true`

- [ ] **Step 2: Write the package-addition script**

```ruby
# /tmp/add_alamofire.rb
require 'xcodeproj'

project_path = 'Wishie.xcodeproj'
project = Xcodeproj::Project.open(project_path)

if project.root_object.package_references.any? { |ref| ref.respond_to?(:repositoryURL) && ref.repositoryURL == 'https://github.com/Alamofire/Alamofire.git' }
  puts 'Alamofire package reference already present — skipping.'
  exit 0
end

package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
package_ref.repositoryURL = 'https://github.com/Alamofire/Alamofire.git'
package_ref.requirement = { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => '5.9.0' }
project.root_object.package_references << package_ref

product_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
product_dep.package = package_ref
product_dep.product_name = 'Alamofire'

wishie_target = project.native_targets.find { |t| t.name == 'Wishie' }
raise 'Wishie target not found' unless wishie_target
wishie_target.package_product_dependencies << product_dep

build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
build_file.product_ref = product_dep
wishie_target.frameworks_build_phase.files << build_file

project.save
puts 'Added Alamofire package dependency to the Wishie target.'
```

- [ ] **Step 3: Run the script from the repo root**

Run: `ruby /tmp/add_alamofire.rb`
Expected: `Added Alamofire package dependency to the Wishie target.`

- [ ] **Step 4: Verify the project file still parses correctly**

Run: `ruby -e "require 'xcodeproj'; Xcodeproj::Project.open('Wishie.xcodeproj'); puts 'OK'"`
Expected: `OK`

- [ ] **Step 5: Resolve the package (requires network access) and confirm the project builds**

Run: `xcodebuild -resolvePackageDependencies -project Wishie.xcodeproj -scheme Wishie`
Expected: exits 0, output ends with `Resolved source packages:` listing `alamofire` at a `5.x` version. This also regenerates `Wishie.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` — no manual edit needed.

If this step can't reach the network in your environment, note it and continue — Task 2's build step is the real gate that needs this resolved.

- [ ] **Step 6: Clean up and commit**

```bash
rm /tmp/add_alamofire.rb
git add Wishie.xcodeproj/project.pbxproj Wishie.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
git commit -m "$(cat <<'EOF'
build: add Alamofire SPM dependency

Wishlist list migration will dispatch its own routes through
Alamofire instead of extending the existing URLSession APIClient.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: `APIRoute` enum

**Files:**
- Create: `Wishie/Networking/APIRoute.swift`
- Test: `WishieTests/APIRouteTests.swift`

**Interfaces:**
- Consumes: `APIConfig.baseURL` (existing, `Wishie/Networking/APIConfig.swift`), `WishieDateFormatting.dateOnly` (existing, `Wishie/Networking/WishieDateFormatting.swift`), `SignUpRequest` (existing, `Wishie/Models/SignUpRequest.swift`)
- Produces: `enum APIRoute: URLRequestConvertible` with cases `.login(email: String, password: String)`, `.signup(SignUpRequest)`, `.refresh(refreshToken: String)`, `.getWishlists`, `.getProfile(id: String)`; `static let requiresAuthHeader: String`; `func asURLRequest() throws -> URLRequest`

- [ ] **Step 1: Write the failing tests**

```swift
// WishieTests/APIRouteTests.swift
import Testing
import Foundation
@testable import Wishie

struct APIRouteTests {
    @Test func getWishlistsBuildsAnAuthenticatedGETRequest() throws {
        let request = try APIRoute.getWishlists.asURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/wishlists")
        #expect(request.value(forHTTPHeaderField: APIRoute.requiresAuthHeader) == "true")
    }

    @Test func getProfileBuildsPathWithTheGivenId() throws {
        let request = try APIRoute.getProfile(id: "u2").asURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/profiles/u2")
        #expect(request.value(forHTTPHeaderField: APIRoute.requiresAuthHeader) == "true")
    }

    @Test func refreshBuildsAnUnauthenticatedPOSTWithTheRefreshTokenBody() throws {
        let request = try APIRoute.refresh(refreshToken: "r1").asURLRequest()

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/auth/refresh")
        #expect(request.value(forHTTPHeaderField: APIRoute.requiresAuthHeader) == nil)
        let body = try #require(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
        #expect(json?["refreshToken"] == "r1")
    }

    @Test func loginBuildsAnUnauthenticatedPOSTWithCredentials() throws {
        let request = try APIRoute.login(email: "a@b.com", password: "pw").asURLRequest()

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/auth/login")
        #expect(request.value(forHTTPHeaderField: APIRoute.requiresAuthHeader) == nil)
        let body = try #require(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
        #expect(json?["email"] == "a@b.com")
        #expect(json?["password"] == "pw")
    }

    @Test func signupBuildsAnUnauthenticatedPOSTWithProfileFields() throws {
        var signUp = SignUpRequest()
        signUp.firstName = "Ada"
        signUp.lastName = "Lovelace"
        signUp.email = "ada@example.com"
        signUp.phone = "123"
        signUp.password = "password1"
        signUp.dateOfBirth = WishieDateFormatting.dateOnly.date(from: "1990-01-01")!

        let request = try APIRoute.signup(signUp).asURLRequest()

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/auth/signup")
        #expect(request.value(forHTTPHeaderField: APIRoute.requiresAuthHeader) == nil)
        let body = try #require(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
        #expect(json?["email"] == "ada@example.com")
        #expect(json?["dateOfBirth"] == "1990-01-01")
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail to compile (type doesn't exist yet)**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/APIRouteTests`
Expected: FAIL — `cannot find 'APIRoute' in scope`

- [ ] **Step 3: Implement `APIRoute`**

```swift
// Wishie/Networking/APIRoute.swift
import Alamofire
import Foundation

enum APIRoute: URLRequestConvertible {
    /// A signal header `asURLRequest()` sets on routes that need a bearer token; `WishieRequestInterceptor`
    /// reads it in `adapt(_:for:completion:)` (where `SessionStore` is reachable, unlike here) and strips
    /// it before the request goes out. `asURLRequest()` itself can't be `async`, so it can't read
    /// `SessionStore` (an actor) directly.
    static let requiresAuthHeader = "X-Wishie-Requires-Auth"

    case login(email: String, password: String)
    case signup(SignUpRequest)
    case refresh(refreshToken: String)
    case getWishlists
    case getProfile(id: String)

    var method: HTTPMethod {
        switch self {
        case .getWishlists, .getProfile: return .get
        case .login, .signup, .refresh: return .post
        }
    }

    var path: String {
        switch self {
        case .login: return "/auth/login"
        case .signup: return "/auth/signup"
        case .refresh: return "/auth/refresh"
        case .getWishlists: return "/wishlists"
        case .getProfile(let id): return "/profiles/\(id)"
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .login, .signup, .refresh: return false
        case .getWishlists, .getProfile: return true
        }
    }

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
        case .getWishlists, .getProfile:
            return request
        }
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/APIRouteTests`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add Wishie/Networking/APIRoute.swift WishieTests/APIRouteTests.swift
git commit -m "$(cat <<'EOF'
feat: add APIRoute enum for Alamofire request dispatch

Login/signup cases are defined for completeness but unused until
AuthenticateService migrates onto this router separately.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: `WishieRequestInterceptor` and `APIService`

**Files:**
- Create: `Wishie/Networking/WishieRequestInterceptor.swift`
- Create: `Wishie/Networking/APIService.swift`
- Test: `WishieTests/APIServiceTests.swift`

**Interfaces:**
- Consumes: `APIRoute` (Task 2), `SessionStore`/`AuthSession`/`APIError` (existing, `Wishie/Networking/`), `MockURLProtocol`/`InMemoryKeychain` (existing test helpers, `WishieTests/`)
- Produces: `protocol APIServiceProtocol { func send<T: Decodable>(_ route: APIRoute) async throws -> T }`, `final class APIService: APIServiceProtocol` with `init(configuration: URLSessionConfiguration = .default, sessionStore: SessionStore = .shared)`, `final class WishieRequestInterceptor: RequestInterceptor` with `init(sessionStore: SessionStore)`

- [ ] **Step 1: Write the failing tests**

```swift
// WishieTests/APIServiceTests.swift
import Testing
import Foundation
@testable import Wishie

@Suite(.serialized)
struct APIServiceTests {
    private func seededKeychain(accessToken: String = "expired-token", refreshToken: String = "refresh-token") -> InMemoryKeychain {
        let keychain = InMemoryKeychain()
        keychain.save(key: "wishie.auth.accessToken", value: accessToken)
        keychain.save(key: "wishie.auth.refreshToken", value: refreshToken)
        keychain.save(key: "wishie.auth.userId", value: "user-1")
        keychain.save(key: "wishie.auth.email", value: "user@example.com")
        return keychain
    }

    private func makeConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return config
    }

    @Test func sendDecodesASuccessfulJSONResponse() async throws {
        struct Sample: Decodable, Equatable { let value: String }
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"value":"ok"}"#.utf8))
        }
        let service = APIService(configuration: makeConfiguration(), sessionStore: SessionStore(keychain: seededKeychain(accessToken: "valid-token")))

        let result: Sample = try await service.send(.getWishlists)

        #expect(result == Sample(value: "ok"))
    }

    @Test func sendAttachesBearerTokenForAuthenticatedRoutes() async throws {
        struct Sample: Decodable { let value: String }
        var capturedAuthHeader: String?
        MockURLProtocol.requestHandler = { request in
            capturedAuthHeader = request.value(forHTTPHeaderField: "Authorization")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"value":"ok"}"#.utf8))
        }
        let service = APIService(configuration: makeConfiguration(), sessionStore: SessionStore(keychain: seededKeychain(accessToken: "valid-token")))

        let _: Sample = try await service.send(.getProfile(id: "u1"))

        #expect(capturedAuthHeader == "Bearer valid-token")
    }

    @Test func sendDoesNotAttachBearerTokenForUnauthenticatedRoutes() async throws {
        struct Sample: Decodable { let value: String }
        var capturedAuthHeader: String? = "not-yet-set"
        MockURLProtocol.requestHandler = { request in
            capturedAuthHeader = request.value(forHTTPHeaderField: "Authorization")
            let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"value":"ok"}"#.utf8))
        }
        let service = APIService(configuration: makeConfiguration(), sessionStore: SessionStore(keychain: InMemoryKeychain()))

        let _: Sample = try await service.send(.login(email: "a@b.com", password: "pw"))

        #expect(capturedAuthHeader == nil)
    }

    @Test func sendThrowsServerErrorWithDecodedMessage() async throws {
        struct Sample: Decodable { let value: String }
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!
            let body = Data(#"{"statusCode":400,"message":"Invalid id","error":"Bad Request"}"#.utf8)
            return (response, body)
        }
        let service = APIService(configuration: makeConfiguration(), sessionStore: SessionStore(keychain: seededKeychain(accessToken: "valid-token")))

        do {
            let _: Sample = try await service.send(.getProfile(id: "u1"))
            Issue.record("expected APIError.server to be thrown")
        } catch let error as APIError {
            #expect(error == .server(statusCode: 400, message: "Invalid id", code: nil))
        }
    }

    @Test func on401ItRefreshesThenRetriesTheOriginalRequestOnce() async throws {
        struct Sample: Decodable { let value: String }
        let keychain = seededKeychain(accessToken: "expired-token", refreshToken: "refresh-token")
        var callCount = 0
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            if request.url!.path == "/auth/refresh" {
                let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
                let body = Data(#"{"accessToken":"new-token","refreshToken":"new-refresh","userId":"user-1","email":"user@example.com"}"#.utf8)
                return (response, body)
            }
            if request.value(forHTTPHeaderField: "Authorization") == "Bearer expired-token" {
                let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
                return (response, Data())
            }
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer new-token")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"value":"ok"}"#.utf8))
        }
        let sessionStore = SessionStore(keychain: keychain)
        let service = APIService(configuration: makeConfiguration(), sessionStore: sessionStore)

        let result: Sample = try await service.send(.getWishlists)

        #expect(result.value == "ok")
        #expect(callCount == 3) // original 401 + refresh + retry
        let refreshed = await sessionStore.current()
        #expect(refreshed?.accessToken == "new-token")
    }

    @Test func whenRefreshFailsSessionIsClearedAndSessionExpiredIsThrown() async throws {
        struct Sample: Decodable { let value: String }
        let keychain = seededKeychain(accessToken: "expired-token", refreshToken: "bad-refresh")
        MockURLProtocol.requestHandler = { request in
            if request.url!.path == "/auth/refresh" {
                let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
                let body = Data(#"{"statusCode":401,"code":"AUTH_REFRESH_TOKEN_INVALID","message":"Invalid Refresh Token"}"#.utf8)
                return (response, body)
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        let sessionStore = SessionStore(keychain: keychain)
        let service = APIService(configuration: makeConfiguration(), sessionStore: sessionStore)

        do {
            let _: Sample = try await service.send(.getWishlists)
            Issue.record("expected APIError.sessionExpired to be thrown")
        } catch let error as APIError {
            #expect(error == .sessionExpired)
        }
        let cleared = await sessionStore.current()
        #expect(cleared == nil)
    }

    @Test func on401ForAnUnauthenticatedRouteThrowsWithoutAttemptingRefresh() async throws {
        struct Sample: Decodable { let value: String }
        let keychain = seededKeychain(accessToken: "valid-token", refreshToken: "refresh-token")
        var callCount = 0
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            if request.url!.path == "/auth/refresh" {
                Issue.record("refresh should not be called for an unauthenticated route")
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            let body = Data(#"{"statusCode":401,"message":"Invalid email or password","error":"Unauthorized"}"#.utf8)
            return (response, body)
        }
        let service = APIService(configuration: makeConfiguration(), sessionStore: SessionStore(keychain: keychain))

        do {
            let _: Sample = try await service.send(.login(email: "a@b.com", password: "wrong"))
            Issue.record("expected APIError.unauthorized to be thrown")
        } catch let error as APIError {
            guard case .unauthorized = error else {
                Issue.record("expected APIError.unauthorized, got \(error)")
                return
            }
        }
        #expect(callCount == 1) // only the original login attempt, no refresh retry
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail to compile**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/APIServiceTests`
Expected: FAIL — `cannot find 'APIService' in scope`

- [ ] **Step 3: Implement `WishieRequestInterceptor`**

```swift
// Wishie/Networking/WishieRequestInterceptor.swift
import Alamofire
import Foundation

/// Attaches the bearer token from `SessionStore` to routes marked via `APIRoute.requiresAuthHeader`,
/// and retries once (after a token refresh) on a 401 — but only for requests that actually carried
/// an `Authorization` header, so an unauthenticated route's own 401 (e.g. bad login credentials)
/// isn't mistaken for an expired session.
final class WishieRequestInterceptor: RequestInterceptor {
    private let sessionStore: SessionStore

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard urlRequest.value(forHTTPHeaderField: APIRoute.requiresAuthHeader) == "true" else {
            completion(.success(urlRequest))
            return
        }
        Task {
            var request = urlRequest
            request.setValue(nil, forHTTPHeaderField: APIRoute.requiresAuthHeader)
            guard let token = await sessionStore.current()?.accessToken else {
                completion(.failure(APIError.sessionExpired))
                return
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            completion(.success(request))
        }
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let statusCode = (request.task?.response as? HTTPURLResponse)?.statusCode,
              statusCode == 401,
              request.request?.value(forHTTPHeaderField: "Authorization") != nil,
              request.retryCount < 1 else {
            completion(.doNotRetry)
            return
        }
        Task {
            do {
                _ = try await sessionStore.refreshedSession { refreshToken in
                    let dataResponse = await session.request(APIRoute.refresh(refreshToken: refreshToken), interceptor: nil)
                        .validate()
                        .serializingDecodable(AuthSession.self)
                        .response
                    switch dataResponse.result {
                    case .success(let authSession):
                        return authSession
                    case .failure(let error):
                        throw APIError.transport(error.localizedDescription)
                    }
                }
                completion(.retry)
            } catch {
                completion(.doNotRetryWithError(APIError.sessionExpired))
            }
        }
    }
}
```

- [ ] **Step 4: Implement `APIService`**

```swift
// Wishie/Networking/APIService.swift
import Alamofire
import Foundation

protocol APIServiceProtocol {
    func send<T: Decodable>(_ route: APIRoute) async throws -> T
}

final class APIService: APIServiceProtocol {
    private let session: Alamofire.Session

    init(configuration: URLSessionConfiguration = .default, sessionStore: SessionStore = .shared) {
        session = Alamofire.Session(configuration: configuration, interceptor: WishieRequestInterceptor(sessionStore: sessionStore))
    }

    func send<T: Decodable>(_ route: APIRoute) async throws -> T {
        let dataResponse = await session.request(route)
            .validate()
            .serializingData()
            .response

        if let afError = dataResponse.error {
            if case .requestRetryFailed(let retryError, _) = afError, let apiError = retryError as? APIError {
                throw apiError
            }
            guard let httpResponse = dataResponse.response else {
                throw APIError.transport(afError.localizedDescription)
            }
            let data = dataResponse.data ?? Data()
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized(APIError.decodeServerError(data: data, statusCode: httpResponse.statusCode))
            }
            throw APIError.decodeServerError(data: data, statusCode: httpResponse.statusCode)
        }

        let data = dataResponse.data ?? Data()
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/APIServiceTests`
Expected: PASS (7 tests)

- [ ] **Step 6: Commit**

```bash
git add Wishie/Networking/WishieRequestInterceptor.swift Wishie/Networking/APIService.swift WishieTests/APIServiceTests.swift
git commit -m "$(cat <<'EOF'
feat: add APIService with Alamofire-based 401 refresh-and-retry

Alamofire-native equivalent of the existing URLSession APIClient's
executeWithRefresh, reusing SessionStore/APIError.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Response DTOs and model mapping

**Files:**
- Create: `Wishie/Models/WishlistResponse.swift`
- Modify: `Wishie/Models/WishlistModel.swift`
- Modify: `Wishie/Models/WishlistItem.swift`
- Test: `WishieTests/WishlistResponseMappingTests.swift`

**Interfaces:**
- Consumes: `WishieDateFormatting.parseServerDate` (existing), `WishlistModel`/`WishlistItem`/`WishlistRole` (existing, `Wishie/Models/`)
- Produces: `struct WishlistMemberResponse: Decodable`, `struct WishlistItemResponse: Decodable`, `struct WishlistResponse: Decodable`; `WishlistModel.init(response: WishlistResponse)`; `WishlistItem.init(response: WishlistItemResponse)`

- [ ] **Step 1: Write the failing tests**

```swift
// WishieTests/WishlistResponseMappingTests.swift
import Testing
import Foundation
@testable import Wishie

struct WishlistResponseMappingTests {
    private func sampleItemResponse(id: String = "i1", isMostDesired: Bool = false) -> WishlistItemResponse {
        WishlistItemResponse(
            id: id, wishlistId: "w1", name: "Lego Set", description: "Fun", imageUrl: "https://x/y.jpg",
            isPicked: true, pickedBy: "u2", itemLink: "https://shop", price: "19.99", isMostDesired: isMostDesired
        )
    }

    private func sampleResponse(members: [WishlistMemberResponse] = [], items: [WishlistItemResponse] = [], isArchived: Bool = false) -> WishlistResponse {
        WishlistResponse(
            id: "w1", name: "Birthday", description: "Party", ownerId: "u1",
            dueDate: "2026-09-01T00:00:00.000Z", colorTheme: "sunset", isArchived: isArchived,
            createdAt: "2026-01-01T00:00:00.000Z", members: members, items: items
        )
    }

    @Test func mapsBasicFieldsAndOwnerId() {
        let wishlist = WishlistModel(response: sampleResponse())

        #expect(wishlist.id == "w1")
        #expect(wishlist.name == "Birthday")
        #expect(wishlist.description == "Party")
        #expect(wishlist.userCreateId == "u1")
        #expect(wishlist.themeColor == "sunset")
        #expect(wishlist.isArchived == false)
    }

    @Test func foldsMembersArrayIntoTheRoleDictionary() {
        let members = [
            WishlistMemberResponse(wishlistId: "w1", userId: "u1", role: "owner", joinedAt: "2026-01-01T00:00:00.000Z"),
            WishlistMemberResponse(wishlistId: "w1", userId: "u2", role: "member", joinedAt: "2026-01-02T00:00:00.000Z")
        ]
        let wishlist = WishlistModel(response: sampleResponse(members: members))

        #expect(wishlist.members["u1"] == .owner)
        #expect(wishlist.members["u2"] == .member)
        #expect(wishlist.isOwner() == false) // isOwner() reads the current device's userId, unset in this test
    }

    @Test func mapsItemsViaWishlistItemInitResponse() {
        let wishlist = WishlistModel(response: sampleResponse(items: [sampleItemResponse()]))

        #expect(wishlist.items.count == 1)
        let item = try #require(wishlist.items.first)
        #expect(item.id == "i1")
        #expect(item.name == "Lego Set")
        #expect(item.image == "https://x/y.jpg")
        #expect(item.isPicked == true)
        #expect(item.pickedUserId == "u2")
        #expect(item.price == "19.99")
    }

    @Test func handlesNilMembersAndItemsAsEmpty() {
        let response = WishlistResponse(
            id: "w1", name: "Birthday", description: "Party", ownerId: "u1",
            dueDate: "2026-09-01T00:00:00.000Z", colorTheme: nil, isArchived: false,
            createdAt: "2026-01-01T00:00:00.000Z", members: nil, items: nil
        )
        let wishlist = WishlistModel(response: response)

        #expect(wishlist.members.isEmpty)
        #expect(wishlist.items.isEmpty)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail to compile**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/WishlistResponseMappingTests`
Expected: FAIL — `cannot find 'WishlistResponse' in scope`

- [ ] **Step 3: Add the response DTOs**

```swift
// Wishie/Models/WishlistResponse.swift
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
```

- [ ] **Step 4: Add `WishlistItem.init(response:)`**

Append to `Wishie/Models/WishlistItem.swift` (after the existing `init(dictionary:)` extension):

```swift
extension WishlistItem {
    init(response: WishlistItemResponse) {
        self.id = response.id
        self.name = response.name
        self.description = response.description
        self.image = response.imageUrl
        self.isPicked = response.isPicked
        self.pickedUserId = response.pickedBy
        self.isMostDesired = response.isMostDesired
        self.localImage = nil
        self.itemLink = response.itemLink
        self.price = response.price
    }
}
```

- [ ] **Step 5: Add `WishlistModel.init(response:)`**

Append to `Wishie/Models/WishlistModel.swift` (after the existing `init(dictionary:)` extension):

```swift
extension WishlistModel {
    init(response: WishlistResponse) {
        self.id = response.id
        self.name = response.name
        self.description = response.description
        self.userCreateId = response.ownerId
        self.dueDate = WishieDateFormatting.parseServerDate(response.dueDate) ?? Date()
        self.themeColor = response.colorTheme
        self.isArchived = response.isArchived
        if let members = response.members {
            self.members = Dictionary(uniqueKeysWithValues: members.compactMap { member in
                WishlistRole(rawValue: member.role).map { (member.userId, $0) }
            })
        } else {
            self.members = [:]
        }
        self.items = (response.items ?? []).map(WishlistItem.init(response:))
    }
}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/WishlistResponseMappingTests`
Expected: PASS (4 tests)

- [ ] **Step 7: Commit**

```bash
git add Wishie/Models/WishlistResponse.swift Wishie/Models/WishlistModel.swift Wishie/Models/WishlistItem.swift WishieTests/WishlistResponseMappingTests.swift
git commit -m "$(cat <<'EOF'
feat: map GET /wishlists response JSON to WishlistModel/WishlistItem

Additive init(response:) alongside the existing Firestore
init(dictionary:) — WishlistDetailScreen's Firestore path is unchanged.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: `WishlistService.getUserWishlists()` / `getProfile(id:)` and owner-profile pairing

**Files:**
- Modify: `Wishie/Services/WishlistService.swift`
- Modify: `WishieTests/MockWishlistService.swift`
- Create: `WishieTests/StubAPIService.swift`
- Test: `WishieTests/WishlistServiceAPITests.swift`
- Test: `WishieTests/WishlistServiceProtocolPairWithOwnerProfilesTests.swift`

**Interfaces:**
- Consumes: `APIServiceProtocol`/`APIRoute` (Task 3), `WishlistResponse`/`WishlistModel.init(response:)` (Task 4), `ProfileResponse`/`UserModel.init(profile:)` (existing, `Wishie/Models/`)
- Produces: `WishlistServiceProtocol.getUserWishlists() async throws -> [WishlistModel]` (signature change — was `Result<[(WishlistModel, UserModel)], Error>`), `WishlistServiceProtocol.getProfile(id: String) async throws -> UserModel` (new), `extension WishlistServiceProtocol { func pairWithOwnerProfiles(_ wishlists: [WishlistModel]) async throws -> [(WishlistModel, UserModel)] }` (new, shared by later tasks)

- [ ] **Step 1: Write the test double for `APIServiceProtocol`**

```swift
// WishieTests/StubAPIService.swift
import Foundation
@testable import Wishie

final class StubAPIService: APIServiceProtocol {
    var sendResults: [Any] = []
    private(set) var sentRoutes: [APIRoute] = []

    func send<T>(_ route: APIRoute) async throws -> T where T: Decodable {
        sentRoutes.append(route)
        guard !sendResults.isEmpty else {
            fatalError("StubAPIService.sendResults exhausted — add a result before calling send()")
        }
        let next = sendResults.removeFirst()
        if let error = next as? Error {
            throw error
        }
        guard let value = next as? T else {
            fatalError("StubAPIService result type mismatch: expected \(T.self), got \(type(of: next))")
        }
        return value
    }
}
```

- [ ] **Step 2: Write the failing tests for `WishlistService`**

```swift
// WishieTests/WishlistServiceAPITests.swift
import Testing
import Foundation
@testable import Wishie

struct WishlistServiceAPITests {
    private func sampleWishlistResponse(id: String = "w1", ownerId: String = "u1") -> WishlistResponse {
        WishlistResponse(
            id: id, name: "Birthday", description: "Party", ownerId: ownerId,
            dueDate: "2026-09-01T00:00:00.000Z", colorTheme: nil, isArchived: false,
            createdAt: "2026-01-01T00:00:00.000Z", members: [], items: []
        )
    }

    private func sampleProfileResponse(id: String = "u1", firstName: String = "Ada") -> ProfileResponse {
        ProfileResponse(id: id, firstName: firstName, lastName: "Lovelace", email: "ada@example.com", phone: "123", dateOfBirth: nil, avatarUrl: nil, interests: [], hasCompletedInterestsSetup: false, createdAt: "2026-01-01T00:00:00.000Z")
    }

    @Test func getUserWishlistsMapsEachResponseEntry() async throws {
        let stub = StubAPIService()
        stub.sendResults = [[sampleWishlistResponse(id: "w1"), sampleWishlistResponse(id: "w2")]]
        let service = WishlistService(apiService: stub)

        let result = try await service.getUserWishlists()

        #expect(result.map(\.id) == ["w1", "w2"])
        #expect(stub.sentRoutes.count == 1)
        guard case .getWishlists = stub.sentRoutes[0] else {
            Issue.record("expected .getWishlists route")
            return
        }
    }

    @Test func getProfileMapsTheResponseAndRequestsTheGivenId() async throws {
        let stub = StubAPIService()
        stub.sendResults = [sampleProfileResponse(id: "u2", firstName: "Grace")]
        let service = WishlistService(apiService: stub)

        let profile = try await service.getProfile(id: "u2")

        #expect(profile.firstName == "Grace")
        guard case .getProfile(let id) = stub.sentRoutes[0] else {
            Issue.record("expected .getProfile route")
            return
        }
        #expect(id == "u2")
    }
}
```

```swift
// WishieTests/WishlistServiceProtocolPairWithOwnerProfilesTests.swift
import Testing
import Foundation
@testable import Wishie

struct WishlistServiceProtocolPairWithOwnerProfilesTests {
    private func wishlist(id: String, ownerId: String) -> WishlistModel {
        WishlistModel(id: id, name: "List \(id)", userCreateId: ownerId, members: [ownerId: .owner])
    }

    @Test func pairsEachWishlistWithItsOwnersProfile() async throws {
        let mock = MockWishlistService()
        mock.profilesById = ["u1": UserModel(dictionary: ["firstName": "Ada"])]

        let pairs = try await mock.pairWithOwnerProfiles([wishlist(id: "w1", ownerId: "u1")])

        #expect(pairs.count == 1)
        #expect(pairs.first?.0.id == "w1")
        #expect(pairs.first?.1.firstName == "Ada")
    }

    @Test func fetchesEachDistinctOwnerOnlyOnce() async throws {
        let mock = MockWishlistService()
        mock.profilesById = ["u1": UserModel(dictionary: ["firstName": "Ada"])]
        let wishlists = [wishlist(id: "w1", ownerId: "u1"), wishlist(id: "w2", ownerId: "u1"), wishlist(id: "w3", ownerId: "u1")]

        let pairs = try await mock.pairWithOwnerProfiles(wishlists)

        #expect(pairs.count == 3)
        #expect(mock.requestedProfileIds == ["u1"])
    }

    @Test func returnsEmptyForAnEmptyList() async throws {
        let mock = MockWishlistService()

        let pairs = try await mock.pairWithOwnerProfiles([])

        #expect(pairs.isEmpty)
        #expect(mock.requestedProfileIds.isEmpty)
    }
}
```

- [ ] **Step 3: Run the tests to verify they fail to compile**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/WishlistServiceAPITests -only-testing:WishieTests/WishlistServiceProtocolPairWithOwnerProfilesTests`
Expected: FAIL — `incorrect argument label` / `cannot find 'getProfile'` etc. (protocol/init mismatches)

- [ ] **Step 4: Update `WishlistServiceProtocol` and `WishlistService`**

In `Wishie/Services/WishlistService.swift`, change the protocol's `getUserWishlists` line and add `getProfile`:

```swift
// before
func getUserWishlists() async throws -> Result<[(WishlistModel, UserModel)], Error>

// after
func getUserWishlists() async throws -> [WishlistModel]
func getProfile(id: String) async throws -> UserModel
```

Add the shared pairing helper right after the protocol declaration (still in the same file):

```swift
extension WishlistServiceProtocol {
    /// Resolves each wishlist's owner profile, deduped per distinct `userCreateId` and fetched
    /// concurrently — shared by `HomeViewModel` and `ArchivedWishlistsViewModel` so owner-profile
    /// resolution isn't duplicated per screen.
    func pairWithOwnerProfiles(_ wishlists: [WishlistModel]) async throws -> [(WishlistModel, UserModel)] {
        let ownerIds = Set(wishlists.map(\.userCreateId))
        let profilesByOwnerId = try await withThrowingTaskGroup(of: (String, UserModel).self) { group in
            for ownerId in ownerIds {
                group.addTask { (ownerId, try await self.getProfile(id: ownerId)) }
            }
            var result: [String: UserModel] = [:]
            for try await (ownerId, profile) in group {
                result[ownerId] = profile
            }
            return result
        }
        return wishlists.compactMap { wishlist in
            profilesByOwnerId[wishlist.userCreateId].map { (wishlist, $0) }
        }
    }
}
```

In the `WishlistService` class, add the `apiService` dependency and the two method implementations:

```swift
class WishlistService: WishlistServiceProtocol {
    private let db = Firestore.firestore()
    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }

    func getUserWishlists() async throws -> [WishlistModel] {
        let responses: [WishlistResponse] = try await apiService.send(.getWishlists)
        return responses.map(WishlistModel.init(response:))
    }

    func getProfile(id: String) async throws -> UserModel {
        let response: ProfileResponse = try await apiService.send(.getProfile(id: id))
        return UserModel(profile: response)
    }

    // ... existing methods unchanged below (createWishlist, upload, getWishlist(by:), etc.) ...
```

Delete the old Firestore-backed `getUserWishlists()` implementation (the one reading `users/{uid}/wishlists` and doing a per-wishlist `getWishlist(by:)` fan-out via `withThrowingTaskGroup`) — it's fully replaced by the version above.

- [ ] **Step 5: Update `MockWishlistService`**

In `WishieTests/MockWishlistService.swift`, replace the stub `getUserWishlists` and add `getProfile`:

```swift
// before
func getUserWishlists() async throws -> Result<[(WishlistModel, UserModel)], Error> {
    .success([])
}

// after
var wishlistsResult: Result<[WishlistModel], Error> = .success([])
func getUserWishlists() async throws -> [WishlistModel] {
    try wishlistsResult.get()
}

var profilesById: [String: UserModel] = [:]
var getProfileError: Error?
private(set) var requestedProfileIds: [String] = []
func getProfile(id: String) async throws -> UserModel {
    requestedProfileIds.append(id)
    if let getProfileError { throw getProfileError }
    return profilesById[id] ?? UserModel()
}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/WishlistServiceAPITests -only-testing:WishieTests/WishlistServiceProtocolPairWithOwnerProfilesTests`
Expected: PASS (5 tests)

- [ ] **Step 7: Build the whole test target to catch any other broken conformance**

Run: `xcodebuild build-for-testing -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: BUILD SUCCEEDED (confirms no other type still expects the old `getUserWishlists()` signature)

- [ ] **Step 8: Commit**

```bash
git add Wishie/Services/WishlistService.swift WishieTests/MockWishlistService.swift WishieTests/StubAPIService.swift WishieTests/WishlistServiceAPITests.swift WishieTests/WishlistServiceProtocolPairWithOwnerProfilesTests.swift
git commit -m "$(cat <<'EOF'
feat: migrate WishlistService.getUserWishlists() to GET /wishlists

Adds getProfile(id:) and a shared pairWithOwnerProfiles() helper so
Home and Archived can resolve each wishlist's owner without bundling
profile data into the service's raw list response, matching the API's
shape (ownerId only, no inline profile).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: `HomeViewModel` — drop Firestore realtime, use the API list

**Files:**
- Modify: `Wishie/Screens/Home/HomeViewModel.swift`
- Modify: `Wishie/Screens/Home/HomeView.swift:259-262`
- Test: `WishieTests/HomeViewModelGetListWishlistTests.swift`

**Interfaces:**
- Consumes: `WishlistServiceProtocol.getUserWishlists()`/`.pairWithOwnerProfiles(_:)` (Task 5), `MockWishlistService` (Task 5), `APIError` (existing)
- Produces: rewritten `HomeViewModel.getListWishlist() async` (now the only fetch method — `refreshWishlists()`, `startObservingWishlists()`, `setWishlistListeners(wishlistIds:)` are deleted)

- [ ] **Step 1: Write the failing tests**

```swift
// WishieTests/HomeViewModelGetListWishlistTests.swift
import Testing
import Foundation
@testable import Wishie

@MainActor
struct HomeViewModelGetListWishlistTests {
    @Test func splitsOwnedAndJoinedWishlistsByRole() async throws {
        UserDefaults.standard.set("me", forKey: WishieConstants.userIdKey)
        defer { UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey) }
        let mock = MockWishlistService()
        mock.wishlistsResult = .success([
            WishlistModel(id: "owned", name: "Mine", userCreateId: "me", members: ["me": .owner]),
            WishlistModel(id: "joined", name: "Theirs", userCreateId: "friend", members: ["me": .member, "friend": .owner])
        ])
        mock.profilesById = ["me": UserModel(dictionary: ["firstName": "Me"]), "friend": UserModel(dictionary: ["firstName": "Friend"])]
        let viewModel = HomeViewModel(service: mock)

        await viewModel.getListWishlist()

        #expect(viewModel.myWishlists.map(\.0.id) == ["owned"])
        #expect(viewModel.myFriendWishlists.map(\.0.id) == ["joined"])
        #expect(viewModel.myFriendWishlists.first?.1.firstName == "Friend")
        #expect(viewModel.isGettingList == false)
    }

    @Test func excludesArchivedWishlistsFromBothLists() async throws {
        UserDefaults.standard.set("me", forKey: WishieConstants.userIdKey)
        defer { UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey) }
        let mock = MockWishlistService()
        mock.wishlistsResult = .success([
            WishlistModel(id: "archived", name: "Old", userCreateId: "me", members: ["me": .owner], isArchived: true)
        ])
        mock.profilesById = ["me": UserModel()]
        let viewModel = HomeViewModel(service: mock)

        await viewModel.getListWishlist()

        #expect(viewModel.myWishlists.isEmpty)
        #expect(viewModel.myFriendWishlists.isEmpty)
    }

    @Test func surfacesAPIErrorMessageOnFailure() async throws {
        UserDefaults.standard.set("me", forKey: WishieConstants.userIdKey)
        defer { UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey) }
        let mock = MockWishlistService()
        mock.wishlistsResult = .failure(APIError.server(statusCode: 500, message: "Server exploded", code: nil))
        let viewModel = HomeViewModel(service: mock)

        await viewModel.getListWishlist()

        #expect(viewModel.errorMessage == "Server exploded")
        #expect(viewModel.isGettingList == false)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail to compile**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/HomeViewModelGetListWishlistTests`
Expected: FAIL — signature/type mismatches against the still-Firestore-backed `HomeViewModel`

- [ ] **Step 3: Rewrite `HomeViewModel`**

Replace the full contents of `Wishie/Screens/Home/HomeViewModel.swift`:

```swift
//
//  HomeViewModel.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 9/2/26.
//

import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var myWishlists: [(WishlistModel, UserModel)] = []
    @Published var myFriendWishlists: [(WishlistModel, UserModel)] = []
    @Published var isGettingList: Bool = false
    @Published var errorMessage: String = ""
    private var service: WishlistServiceProtocol

    init(service: WishlistServiceProtocol = WishlistService()) {
        self.service = service
    }

    func getListWishlist() async {
        guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else { return }
        isGettingList = true
        defer { isGettingList = false }
        do {
            let wishlists = try await service.getUserWishlists().filter { !$0.isArchived }
            let owned = wishlists.filter { $0.members[userId] == .owner }
            let joined = wishlists.filter { $0.members[userId] == .member }
            async let ownedPairs = service.pairWithOwnerProfiles(owned)
            async let joinedPairs = service.pairWithOwnerProfiles(joined)
            (myWishlists, myFriendWishlists) = try await (ownedPairs, joinedPairs)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func deleteWishlist(wishlistId: String) async {
        do {
            let result = try await service.deleteWishlist(wishlistId: wishlistId)
            switch result {
            case .success:
                await getListWishlist()
            case .failure(let failure):
                self.errorMessage = failure.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func leaveWishlist(wishlistId: String) async {
        do {
            let result = try await service.leaveWishlist(wishListId: wishlistId)
            switch result {
            case .success:
                await getListWishlist()
            case .failure(let failure):
                self.errorMessage = failure.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func archiveWishlist(wishlistId: String) async {
        do {
            let result = try await service.setArchived(wishlistId: wishlistId, isArchived: true)
            switch result {
            case .success:
                await getListWishlist()
            case .failure(let failure):
                self.errorMessage = failure.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
```

- [ ] **Step 4: Update `HomeView.swift`'s `.task`**

In `Wishie/Screens/Home/HomeView.swift`, change:

```swift
// before (around line 259)
.task {
    await authViewModel.getUserInfo()
    homeViewModel.startObservingWishlists()
}
```

to:

```swift
// after
.task {
    await authViewModel.getUserInfo()
    await homeViewModel.getListWishlist()
}
```

(The existing `.refreshable { await homeViewModel.getListWishlist() }` pull-to-refresh a few lines below needs no change.)

- [ ] **Step 5: Run the tests to verify they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/HomeViewModelGetListWishlistTests`
Expected: PASS (3 tests)

- [ ] **Step 6: Build the app target to confirm `HomeView.swift` still compiles**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: BUILD SUCCEEDED

- [ ] **Step 7: Commit**

```bash
git add Wishie/Screens/Home/HomeViewModel.swift Wishie/Screens/Home/HomeView.swift WishieTests/HomeViewModelGetListWishlistTests.swift
git commit -m "$(cat <<'EOF'
feat: fetch Home's wishlist list from the API instead of Firestore

Drops the Firestore realtime-listener refresh path (no equivalent on
the REST API per API.md) in favor of task-on-appear plus the existing
pull-to-refresh.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: `ArchivedWishlistsViewModel` — use the API list

**Files:**
- Modify: `Wishie/Screens/Archived/ArchivedWishlistsViewModel.swift`
- Test: `WishieTests/ArchivedWishlistsViewModelTests.swift`

**Interfaces:**
- Consumes: `WishlistServiceProtocol.getUserWishlists()`/`.pairWithOwnerProfiles(_:)` (Task 5), `MockWishlistService` (Task 5)
- Produces: rewritten `ArchivedWishlistsViewModel.loadArchivedWishlists() async`

- [ ] **Step 1: Write the failing tests**

```swift
// WishieTests/ArchivedWishlistsViewModelTests.swift
import Testing
import Foundation
@testable import Wishie

@MainActor
struct ArchivedWishlistsViewModelTests {
    @Test func showsOnlySelfOwnedArchivedWishlists() async throws {
        UserDefaults.standard.set("me", forKey: WishieConstants.userIdKey)
        defer { UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey) }
        let mock = MockWishlistService()
        mock.wishlistsResult = .success([
            WishlistModel(id: "archived-owned", name: "Old", userCreateId: "me", members: ["me": .owner], isArchived: true),
            WishlistModel(id: "active-owned", name: "Active", userCreateId: "me", members: ["me": .owner], isArchived: false),
            WishlistModel(id: "archived-joined", name: "Friend's", userCreateId: "friend", members: ["me": .member, "friend": .owner], isArchived: true)
        ])
        mock.profilesById = ["me": UserModel(dictionary: ["firstName": "Me"])]
        let viewModel = ArchivedWishlistsViewModel(service: mock)

        await viewModel.loadArchivedWishlists()

        #expect(viewModel.archivedWishlists.map(\.0.id) == ["archived-owned"])
        #expect(viewModel.isLoading == false)
    }

    @Test func surfacesAPIErrorMessageOnFailure() async throws {
        UserDefaults.standard.set("me", forKey: WishieConstants.userIdKey)
        defer { UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey) }
        let mock = MockWishlistService()
        mock.wishlistsResult = .failure(APIError.server(statusCode: 500, message: "Server exploded", code: nil))
        let viewModel = ArchivedWishlistsViewModel(service: mock)

        await viewModel.loadArchivedWishlists()

        #expect(viewModel.errorMessage == "Server exploded")
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/ArchivedWishlistsViewModelTests`
Expected: FAIL — asserts against the still-Firestore-backed `ArchivedWishlistsViewModel`

- [ ] **Step 3: Rewrite `loadArchivedWishlists()`**

Replace the full contents of `Wishie/Screens/Archived/ArchivedWishlistsViewModel.swift`:

```swift
//
//  ArchivedWishlistsViewModel.swift
//  Wishie
//

import Foundation

@MainActor
class ArchivedWishlistsViewModel: ObservableObject {
    @Published var archivedWishlists: [(WishlistModel, UserModel)] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""

    private var service: WishlistServiceProtocol
    init(service: WishlistServiceProtocol = WishlistService()) {
        self.service = service
    }

    func loadArchivedWishlists() async {
        guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let wishlists = try await service.getUserWishlists()
            let owned = wishlists.filter { $0.members[userId] == .owner && $0.isArchived }
            archivedWishlists = try await service.pairWithOwnerProfiles(owned)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func unarchiveWishlist(wishlistId: String) async {
        do {
            let result = try await service.setArchived(wishlistId: wishlistId, isArchived: false)
            switch result {
            case .success:
                await loadArchivedWishlists()
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func deleteWishlist(wishlistId: String) async {
        do {
            let result = try await service.deleteWishlist(wishlistId: wishlistId)
            switch result {
            case .success:
                await loadArchivedWishlists()
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/ArchivedWishlistsViewModelTests`
Expected: PASS (2 tests)

- [ ] **Step 5: Run the full test suite to confirm nothing else broke**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: BUILD SUCCEEDED, all tests pass

- [ ] **Step 6: Commit**

```bash
git add Wishie/Screens/Archived/ArchivedWishlistsViewModel.swift WishieTests/ArchivedWishlistsViewModelTests.swift
git commit -m "$(cat <<'EOF'
feat: fetch Archived wishlists from the API instead of Firestore

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Manual verification (after all tasks)

With `wishie-server` running locally (`npm run start:dev` in that repo) and the app pointed at it (Simulator uses `http://localhost:3000` automatically per `APIConfig`):

1. Log in / sign up in the app (still Firestore-backed for account creation per the earlier auth migration — unaffected by this plan).
2. Via `GET /api-docs` (Swagger) on the running server, call `POST /wishlists` as the logged-in user's id to create a wishlist directly against the API (`POST /wishlists` isn't wired up in the app yet — creation stays Firestore-backed per this plan's scope).
3. Confirm the app's Home screen "My list" tab shows it after pull-to-refresh (or relaunching the tab).
4. From a second test account, call `POST /wishlists/join/:code` (after `GET /wishlists/:id/share` as the owner) to join that wishlist, then confirm it shows up under that second account's "Friend's list" tab with the first account's name/avatar.
5. Archive it (`PATCH /wishlists/:id/archive`) via Swagger and confirm it disappears from Home and appears on the Archived screen for the owner.
