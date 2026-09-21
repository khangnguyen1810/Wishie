# Firebase Auth → Wishie API Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `AuthenticateService`'s Firebase/Firestore/Supabase-Storage internals with HTTP calls to the Wishie API's `/auth/*` and `/profiles/*` endpoints (per `API.md`), covering signup, login, Google sign-in, password reset, logout, and profile CRUD — while keeping every other screen's call sites unchanged.

**Architecture:** A new `Wishie/Networking/` layer (`APIConfig`, `APIError`, `Endpoint`, `APIClient`, `SessionStore`) provides a reusable, `async/await`-based HTTP client with an actor-backed session store that transparently refreshes an expired access token (via `POST /auth/refresh`) and retries the failed request once. `AuthenticateService` and `AuthViewModel` are rewritten on top of it, fully `async/await`, dropping all Firebase/Firestore/Supabase types.

**Tech Stack:** Swift, `URLSession` (no third-party networking library), Swift's `actor` for the session store, Swift Testing (`import Testing`, `@Test`, `#expect`) for all new tests — this repo does not use XCTest for new test files.

## Global Constraints

- Design source of truth: `docs/superpowers/specs/2026-08-07-firebase-auth-to-api-migration-design.md`. Endpoint shapes/error formats source of truth: `API.md` (repo root).
- Test framework: Swift Testing (`import Testing`, `@Test func …`, `#expect(...)`, `Issue.record(...)`), matching every existing file under `WishieTests/`. Do not add XCTest-based tests.
- Build/test command: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/<SuiteName>` (run from `/Users/nguyenkhanghuu/Wishie`). Substitute the actual suite name per task.
- `Info.plist` already has `NSAllowsArbitraryLoads = true` (added previously) — no ATS change is needed for local HTTP testing.
- Out of scope (do not touch): `WishlistService`, `GiftSuggestionService`, Firestore-backed wishlist data, Supabase Storage for wishlist item images, `FirebaseApp.configure()`, `GoogleService-Info.plist`. These still depend on Firebase/Supabase directly and are covered by a later migration.
- Do not remove the `FirebaseAuth`, `Firebase`, `FirebaseFirestore`, or `Supabase` SPM dependencies from the project — other files still import them.
- No backend base URL exists yet beyond local dev (`API.md`: "not deployed yet"). `APIConfig` only needs to support Simulator (`http://localhost:3000`) and physical-device (LAN IP) local dev.
- The Google OAuth **web** client ID needed for `POST /auth/google` must match the backend's `GOOGLE_CLIENT_ID` — the user has confirmed this is already configured on the backend, but the plan puts a literal placeholder string in `WishieConstants.googleWebClientID` that must be replaced with the real value before Google Sign-In can be manually verified (Task 7).

---

## Task 1: Networking primitives — `AuthSession`, `APIError`, `Endpoint`

**Files:**
- Create: `Wishie/Networking/AuthSession.swift`
- Create: `Wishie/Networking/APIError.swift`
- Create: `Wishie/Networking/Endpoint.swift`
- Test: `WishieTests/AuthSessionTests.swift`
- Test: `WishieTests/APIErrorTests.swift`
- Test: `WishieTests/EndpointTests.swift`

**Interfaces:**
- Produces: `struct AuthSession: Codable, Equatable, Sendable { let accessToken, refreshToken, userId, email: String }` — matches `API.md`'s `/auth/signup`, `/auth/login`, `/auth/google`, `/auth/refresh` response shape field-for-field.
- Produces: `enum APIError: Error, LocalizedError, Equatable { case server(statusCode: Int, message: String, code: String?), unauthorized, sessionExpired, invalidResponse, transport(String) }`, plus `static func decodeServerError(data: Data, statusCode: Int) -> APIError`.
- Produces: `struct Endpoint { enum Body { case json(Data), multipart(fieldName: String, fileName: String, mimeType: String, fileData: Data), none }; let path, method: String; let body: Body; let requiresAuth: Bool }` with static factories `.get(_:requiresAuth:)`, `.post(_:json:requiresAuth:)`, `.patch(_:json:requiresAuth:)`, `.postMultipart(_:fieldName:fileName:mimeType:fileData:requiresAuth:)`.

- [ ] **Step 1: Write the failing tests for `AuthSession`**

Create `WishieTests/AuthSessionTests.swift`:

```swift
import Testing
@testable import Wishie

struct AuthSessionTests {
    @Test func decodesFromAPISignupResponseShape() throws {
        let json = """
        {
          "accessToken": "eyJhbGciOi...",
          "refreshToken": "v1.Mre...",
          "userId": "b3f1-uuid",
          "email": "user@example.com"
        }
        """.data(using: .utf8)!

        let session = try JSONDecoder().decode(AuthSession.self, from: json)

        #expect(session.accessToken == "eyJhbGciOi...")
        #expect(session.refreshToken == "v1.Mre...")
        #expect(session.userId == "b3f1-uuid")
        #expect(session.email == "user@example.com")
    }
}
```

- [ ] **Step 2: Run it to confirm it fails to compile (no `AuthSession` type yet)**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/AuthSessionTests`
Expected: FAIL — build error, `Cannot find type 'AuthSession' in scope`.

- [ ] **Step 3: Create `AuthSession`**

Create `Wishie/Networking/AuthSession.swift`:

```swift
import Foundation

struct AuthSession: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
    let userId: String
    let email: String
}
```

- [ ] **Step 4: Run the test again to confirm it passes**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/AuthSessionTests`
Expected: PASS

- [ ] **Step 5: Write the failing tests for `APIError`**

Create `WishieTests/APIErrorTests.swift`:

```swift
import Testing
import Foundation
@testable import Wishie

struct APIErrorTests {
    @Test func decodesGenericNestErrorShape() {
        let json = """
        {"statusCode":400,"message":"Invalid email","error":"Bad Request"}
        """.data(using: .utf8)!

        let error = APIError.decodeServerError(data: json, statusCode: 400)

        #expect(error == .server(statusCode: 400, message: "Invalid email", code: nil))
    }

    @Test func decodesRefreshLogoutErrorShapeWithCode() {
        let json = """
        {"statusCode":401,"code":"AUTH_REFRESH_TOKEN_INVALID","message":"Invalid Refresh Token"}
        """.data(using: .utf8)!

        let error = APIError.decodeServerError(data: json, statusCode: 401)

        #expect(error == .server(statusCode: 401, message: "Invalid Refresh Token", code: "AUTH_REFRESH_TOKEN_INVALID"))
        #expect(error.code == "AUTH_REFRESH_TOKEN_INVALID")
    }

    @Test func decodesMessageArrayFromValidationErrors() {
        let json = """
        {"statusCode":400,"message":["email must be valid","password too short"],"error":"Bad Request"}
        """.data(using: .utf8)!

        let error = APIError.decodeServerError(data: json, statusCode: 400)

        #expect(error == .server(statusCode: 400, message: "email must be valid\\npassword too short", code: nil))
    }

    @Test func fallsBackToGenericMessageWhenBodyIsUnparseable() {
        let error = APIError.decodeServerError(data: Data(), statusCode: 500)

        #expect(error == .server(statusCode: 500, message: "Unexpected error", code: nil))
    }
}
```

- [ ] **Step 6: Run it to confirm it fails to compile**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/APIErrorTests`
Expected: FAIL — `Cannot find type 'APIError' in scope`.

- [ ] **Step 7: Create `APIError`**

Create `Wishie/Networking/APIError.swift`:

```swift
import Foundation

enum APIError: Error, LocalizedError, Equatable {
    case server(statusCode: Int, message: String, code: String?)
    case unauthorized
    case sessionExpired
    case invalidResponse
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .server(_, let message, _): return message
        case .unauthorized: return "Unauthorized."
        case .sessionExpired: return "Your session has expired. Please log in again."
        case .invalidResponse: return "Unexpected server response."
        case .transport(let message): return message
        }
    }

    var code: String? {
        if case .server(_, _, let code) = self { return code }
        return nil
    }

    static func decodeServerError(data: Data, statusCode: Int) -> APIError {
        struct ServerErrorBody: Decodable {
            let statusCode: Int?
            let message: String
            let code: String?

            enum CodingKeys: String, CodingKey { case statusCode, message, code }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                statusCode = try container.decodeIfPresent(Int.self, forKey: .statusCode)
                code = try container.decodeIfPresent(String.self, forKey: .code)
                if let single = try? container.decode(String.self, forKey: .message) {
                    message = single
                } else if let multiple = try? container.decode([String].self, forKey: .message) {
                    message = multiple.joined(separator: "\n")
                } else {
                    message = "Unexpected error"
                }
            }
        }
        guard let body = try? JSONDecoder().decode(ServerErrorBody.self, from: data) else {
            return .server(statusCode: statusCode, message: "Unexpected error", code: nil)
        }
        return .server(statusCode: body.statusCode ?? statusCode, message: body.message, code: body.code)
    }
}
```

- [ ] **Step 8: Run the tests again to confirm they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/APIErrorTests`
Expected: PASS (all 4 tests)

- [ ] **Step 9: Write the failing tests for `Endpoint`**

Create `WishieTests/EndpointTests.swift`:

```swift
import Testing
import Foundation
@testable import Wishie

struct EndpointTests {
    @Test func getDefaultsToRequiringAuth() {
        let endpoint = Endpoint.get("/profiles/me")

        #expect(endpoint.method == "GET")
        #expect(endpoint.path == "/profiles/me")
        #expect(endpoint.requiresAuth == true)
        if case .none = endpoint.body {} else { Issue.record("expected .none body") }
    }

    @Test func postDefaultsToNotRequiringAuth() {
        let json = Data("{}".utf8)
        let endpoint = Endpoint.post("/auth/login", json: json)

        #expect(endpoint.method == "POST")
        #expect(endpoint.requiresAuth == false)
        if case .json(let data) = endpoint.body {
            #expect(data == json)
        } else {
            Issue.record("expected .json body")
        }
    }

    @Test func patchDefaultsToRequiringAuth() {
        let json = Data("{}".utf8)
        let endpoint = Endpoint.patch("/profiles/me", json: json)

        #expect(endpoint.method == "PATCH")
        #expect(endpoint.requiresAuth == true)
    }

    @Test func postMultipartCarriesFileFields() {
        let fileData = Data([0x01, 0x02])
        let endpoint = Endpoint.postMultipart("/profiles/me/avatar", fieldName: "file", fileName: "u1.jpg", mimeType: "image/jpeg", fileData: fileData)

        #expect(endpoint.method == "POST")
        #expect(endpoint.requiresAuth == true)
        if case .multipart(let fieldName, let fileName, let mimeType, let data) = endpoint.body {
            #expect(fieldName == "file")
            #expect(fileName == "u1.jpg")
            #expect(mimeType == "image/jpeg")
            #expect(data == fileData)
        } else {
            Issue.record("expected .multipart body")
        }
    }
}
```

- [ ] **Step 10: Run it to confirm it fails to compile**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/EndpointTests`
Expected: FAIL — `Cannot find type 'Endpoint' in scope`.

- [ ] **Step 11: Create `Endpoint`**

Create `Wishie/Networking/Endpoint.swift`:

```swift
import Foundation

struct Endpoint {
    enum Body {
        case json(Data)
        case multipart(fieldName: String, fileName: String, mimeType: String, fileData: Data)
        case none
    }

    let path: String
    let method: String
    let body: Body
    let requiresAuth: Bool

    static func get(_ path: String, requiresAuth: Bool = true) -> Endpoint {
        Endpoint(path: path, method: "GET", body: .none, requiresAuth: requiresAuth)
    }

    static func post(_ path: String, json: Data? = nil, requiresAuth: Bool = false) -> Endpoint {
        Endpoint(path: path, method: "POST", body: json.map(Body.json) ?? .none, requiresAuth: requiresAuth)
    }

    static func patch(_ path: String, json: Data, requiresAuth: Bool = true) -> Endpoint {
        Endpoint(path: path, method: "PATCH", body: .json(json), requiresAuth: requiresAuth)
    }

    static func postMultipart(_ path: String, fieldName: String, fileName: String, mimeType: String, fileData: Data, requiresAuth: Bool = true) -> Endpoint {
        Endpoint(path: path, method: "POST", body: .multipart(fieldName: fieldName, fileName: fileName, mimeType: mimeType, fileData: fileData), requiresAuth: requiresAuth)
    }
}
```

- [ ] **Step 12: Run the tests again to confirm they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/EndpointTests`
Expected: PASS (all 4 tests)

- [ ] **Step 13: Commit**

```bash
git add Wishie/Networking/AuthSession.swift Wishie/Networking/APIError.swift Wishie/Networking/Endpoint.swift WishieTests/AuthSessionTests.swift WishieTests/APIErrorTests.swift WishieTests/EndpointTests.swift
git commit -m "feat: add AuthSession, APIError, and Endpoint networking primitives"
```

---

## Task 2: `APIConfig` (base URL) and `WishieDateFormatting`

**Files:**
- Create: `Wishie/Networking/APIConfig.swift`
- Create: `Wishie/Networking/WishieDateFormatting.swift`
- Test: `WishieTests/APIConfigTests.swift`
- Test: `WishieTests/WishieDateFormattingTests.swift`

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: `enum APIConfig { static let baseURL: URL }`.
- Produces: `enum WishieDateFormatting { static let dateOnly: DateFormatter; static func parseServerDate(_ string: String) -> Date? }`.

- [ ] **Step 1: Write the failing test for `APIConfig`**

Create `WishieTests/APIConfigTests.swift`:

```swift
import Testing
@testable import Wishie

struct APIConfigTests {
    @Test func baseURLIsAWellFormedLocalHTTPURLOnPort3000() {
        #expect(APIConfig.baseURL.scheme == "http")
        #expect(APIConfig.baseURL.port == 3000)
    }
}
```

- [ ] **Step 2: Run it to confirm it fails to compile**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/APIConfigTests`
Expected: FAIL — `Cannot find 'APIConfig' in scope`.

- [ ] **Step 3: Create `APIConfig`**

Create `Wishie/Networking/APIConfig.swift`:

```swift
import Foundation

enum APIConfig {
    #if targetEnvironment(simulator)
    static let baseURL = URL(string: "http://localhost:3000")!
    #else
    // wishie-server isn't deployed yet (see API.md — "not deployed yet"). For physical-device
    // testing, replace this with your Mac's LAN IP, found via `ipconfig getifaddr en0`.
    // It changes whenever you reconnect to a different Wi-Fi network.
    static let baseURL = URL(string: "http://192.168.1.100:3000")!
    #endif
}
```

- [ ] **Step 4: Run the test again to confirm it passes**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/APIConfigTests`
Expected: PASS

- [ ] **Step 5: Write the failing tests for `WishieDateFormatting`**

Create `WishieTests/WishieDateFormattingTests.swift`:

```swift
import Testing
import Foundation
@testable import Wishie

struct WishieDateFormattingTests {
    @Test func dateOnlyFormatsAsYYYYMMDD() {
        var components = DateComponents()
        components.year = 2000
        components.month = 1
        components.day = 1
        let date = Calendar(identifier: .iso8601).date(from: components)!

        #expect(WishieDateFormatting.dateOnly.string(from: date) == "2000-01-01")
    }

    @Test func parseServerDateHandlesDateOnlyStrings() {
        #expect(WishieDateFormatting.parseServerDate("2000-01-01") != nil)
    }

    @Test func parseServerDateHandlesFullISODatetimeStrings() {
        #expect(WishieDateFormatting.parseServerDate("2026-08-07T10:00:00.000Z") != nil)
    }

    @Test func parseServerDateReturnsNilForGarbage() {
        #expect(WishieDateFormatting.parseServerDate("not-a-date") == nil)
    }
}
```

- [ ] **Step 6: Run it to confirm it fails to compile**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/WishieDateFormattingTests`
Expected: FAIL — `Cannot find 'WishieDateFormatting' in scope`.

- [ ] **Step 7: Create `WishieDateFormatting`**

Create `Wishie/Networking/WishieDateFormatting.swift`:

```swift
import Foundation

enum WishieDateFormatting {
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func parseServerDate(_ string: String) -> Date? {
        if let date = ISO8601DateFormatter().date(from: string) {
            return date
        }
        return dateOnly.date(from: string)
    }
}
```

- [ ] **Step 8: Run the tests again to confirm they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/WishieDateFormattingTests`
Expected: PASS (all 4 tests)

- [ ] **Step 9: Commit**

```bash
git add Wishie/Networking/APIConfig.swift Wishie/Networking/WishieDateFormatting.swift WishieTests/APIConfigTests.swift WishieTests/WishieDateFormattingTests.swift
git commit -m "feat: add APIConfig base URL selection and server date parsing helpers"
```

---

## Task 3: `SessionStore` (Keychain-backed session with single-flight refresh coordination)

**Files:**
- Create: `Wishie/Networking/SessionStore.swift`
- Test: `WishieTests/InMemoryKeychain.swift` (test double, not a test suite)
- Test: `WishieTests/SessionStoreTests.swift`

**Interfaces:**
- Consumes: `AuthSession` (Task 1), `APIError.sessionExpired` (Task 1).
- Consumes: `KeychainManager.shared` (`Wishie/Manager/KeychainManager.swift`) — existing class with `save(key:value:)`, `load(key:) -> String?`, `delete(key:)`. Not modified; a new `KeychainStoring` protocol is declared alongside `SessionStore` and `KeychainManager` is retroactively conformed via an empty `extension KeychainManager: KeychainStoring {}`.
- Produces: `protocol KeychainStoring { func save(key: String, value: String); func load(key: String) -> String?; func delete(key: String) }`.
- Produces: `actor SessionStore { static let shared: SessionStore; init(keychain: KeychainStoring = KeychainManager.shared); func current() -> AuthSession?; func save(_ session: AuthSession); func clear(); func refreshedSession(using refresher: @escaping @Sendable (String) async throws -> AuthSession) async throws -> AuthSession }`. Later tasks (`APIClient` in Task 4, `AuthenticateService`/`AuthViewModel` in Tasks 5–6) depend on this exact signature.

- [ ] **Step 1: Add the in-memory keychain test double**

Create `WishieTests/InMemoryKeychain.swift`:

```swift
import Foundation
@testable import Wishie

final class InMemoryKeychain: KeychainStoring {
    private var storage: [String: String] = [:]

    func save(key: String, value: String) {
        storage[key] = value
    }

    func load(key: String) -> String? {
        storage[key]
    }

    func delete(key: String) {
        storage[key] = nil
    }
}
```

(This file won't compile until `KeychainStoring` exists — that's expected; it'll compile once Step 3 below lands. Both files are added before the first test run.)

- [ ] **Step 2: Write the failing tests for `SessionStore`**

Create `WishieTests/SessionStoreTests.swift`:

```swift
import Testing
import Foundation
@testable import Wishie

struct SessionStoreTests {
    private func sampleSession(accessToken: String = "a", refreshToken: String = "r") -> AuthSession {
        AuthSession(accessToken: accessToken, refreshToken: refreshToken, userId: "u1", email: "user@example.com")
    }

    @Test func savedSessionIsReturnedByCurrent() async {
        let store = SessionStore(keychain: InMemoryKeychain())
        let session = sampleSession()

        await store.save(session)
        let loaded = await store.current()

        #expect(loaded == session)
    }

    @Test func currentReturnsNilWhenNothingSaved() async {
        let store = SessionStore(keychain: InMemoryKeychain())

        let loaded = await store.current()

        #expect(loaded == nil)
    }

    @Test func clearRemovesTheSession() async {
        let store = SessionStore(keychain: InMemoryKeychain())
        await store.save(sampleSession())

        await store.clear()
        let loaded = await store.current()

        #expect(loaded == nil)
    }

    @Test func refreshedSessionPersistsTheNewSession() async throws {
        let store = SessionStore(keychain: InMemoryKeychain())
        await store.save(sampleSession())
        let newSession = sampleSession(accessToken: "new", refreshToken: "new-refresh")

        let result = try await store.refreshedSession { _ in newSession }

        #expect(result == newSession)
        let stored = await store.current()
        #expect(stored == newSession)
    }

    @Test func concurrentRefreshCallsShareOneInFlightAttempt() async throws {
        let store = SessionStore(keychain: InMemoryKeychain())
        await store.save(sampleSession())

        actor CallCounter {
            private(set) var count = 0
            func increment() { count += 1 }
        }
        let counter = CallCounter()
        let newSession = sampleSession(accessToken: "new", refreshToken: "new-refresh")

        async let first = store.refreshedSession { _ in
            await counter.increment()
            try await Task.sleep(for: .milliseconds(50))
            return newSession
        }
        async let second = store.refreshedSession { _ in
            await counter.increment()
            try await Task.sleep(for: .milliseconds(50))
            return newSession
        }
        _ = try await (first, second)

        let callCount = await counter.count
        #expect(callCount == 1)
    }

    @Test func refreshFailureClearsTheStoredSession() async {
        let store = SessionStore(keychain: InMemoryKeychain())
        await store.save(sampleSession())
        struct SampleError: Error {}

        do {
            _ = try await store.refreshedSession { _ in throw SampleError() }
            Issue.record("expected refreshedSession to throw")
        } catch {
            // expected
        }

        let loaded = await store.current()
        #expect(loaded == nil)
    }

    @Test func refreshWithNoStoredSessionThrowsSessionExpired() async {
        let store = SessionStore(keychain: InMemoryKeychain())

        do {
            _ = try await store.refreshedSession { _ in
                Issue.record("refresher should not be called with no stored session")
                throw APIError.sessionExpired
            }
            Issue.record("expected sessionExpired to be thrown")
        } catch let error as APIError {
            #expect(error == .sessionExpired)
        } catch {
            Issue.record("unexpected error type: \(error)")
        }
    }
}
```

- [ ] **Step 3: Run it to confirm it fails to compile**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/SessionStoreTests`
Expected: FAIL — `Cannot find type 'SessionStore' in scope` / `Cannot find type 'KeychainStoring' in scope`.

- [ ] **Step 4: Create `SessionStore`**

Create `Wishie/Networking/SessionStore.swift`:

```swift
import Foundation

protocol KeychainStoring {
    func save(key: String, value: String)
    func load(key: String) -> String?
    func delete(key: String)
}

extension KeychainManager: KeychainStoring {}

actor SessionStore {
    static let shared = SessionStore()

    private let keychain: KeychainStoring
    private let accessTokenKey = "wishie.auth.accessToken"
    private let refreshTokenKey = "wishie.auth.refreshToken"
    private let userIdKey = "wishie.auth.userId"
    private let emailKey = "wishie.auth.email"

    private var cachedSession: AuthSession?
    private var refreshTask: Task<AuthSession, Error>?

    init(keychain: KeychainStoring = KeychainManager.shared) {
        self.keychain = keychain
    }

    func current() -> AuthSession? {
        if let cachedSession {
            return cachedSession
        }
        guard let accessToken = keychain.load(key: accessTokenKey),
              let refreshToken = keychain.load(key: refreshTokenKey),
              let userId = keychain.load(key: userIdKey),
              let email = keychain.load(key: emailKey) else {
            return nil
        }
        let session = AuthSession(accessToken: accessToken, refreshToken: refreshToken, userId: userId, email: email)
        cachedSession = session
        return session
    }

    func save(_ session: AuthSession) {
        keychain.save(key: accessTokenKey, value: session.accessToken)
        keychain.save(key: refreshTokenKey, value: session.refreshToken)
        keychain.save(key: userIdKey, value: session.userId)
        keychain.save(key: emailKey, value: session.email)
        cachedSession = session
    }

    func clear() {
        keychain.delete(key: accessTokenKey)
        keychain.delete(key: refreshTokenKey)
        keychain.delete(key: userIdKey)
        keychain.delete(key: emailKey)
        cachedSession = nil
        refreshTask = nil
    }

    func refreshedSession(using refresher: @escaping @Sendable (String) async throws -> AuthSession) async throws -> AuthSession {
        if let refreshTask {
            return try await refreshTask.value
        }
        guard let refreshToken = current()?.refreshToken else {
            throw APIError.sessionExpired
        }
        let task = Task<AuthSession, Error> {
            try await refresher(refreshToken)
        }
        refreshTask = task
        do {
            let newSession = try await task.value
            refreshTask = nil
            save(newSession)
            return newSession
        } catch {
            refreshTask = nil
            clear()
            throw APIError.sessionExpired
        }
    }
}
```

- [ ] **Step 5: Run the tests again to confirm they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/SessionStoreTests`
Expected: PASS (all 7 tests)

- [ ] **Step 6: Commit**

```bash
git add Wishie/Networking/SessionStore.swift WishieTests/InMemoryKeychain.swift WishieTests/SessionStoreTests.swift
git commit -m "feat: add SessionStore with Keychain persistence and single-flight refresh"
```

---

## Task 4: `APIClient` (request execution, error decoding, 401 refresh-and-retry)

**Files:**
- Create: `Wishie/Networking/APIClient.swift`
- Test: `WishieTests/MockURLProtocol.swift` (test double, not a test suite)
- Test: `WishieTests/APIClientTests.swift`

**Interfaces:**
- Consumes: `Endpoint`, `AuthSession`, `APIError` (Task 1); `SessionStore` (Task 3), exact signature `refreshedSession(using: @escaping @Sendable (String) async throws -> AuthSession) async throws -> AuthSession`.
- Produces: `protocol APIClientProtocol { func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T; func sendNoContent(_ endpoint: Endpoint) async throws }`. Task 5 (`AuthenticateService`) depends on this exact protocol.
- Produces: `final class APIClient: APIClientProtocol { init(session: URLSession = .shared, baseURL: URL = APIConfig.baseURL, sessionStore: SessionStore = .shared) }`.

- [ ] **Step 1: Add the `MockURLProtocol` test double**

Create `WishieTests/MockURLProtocol.swift`:

```swift
import Foundation

final class MockURLProtocol: URLProtocol {
    static var requestHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}
```

- [ ] **Step 2: Write the failing tests for `APIClient`**

Create `WishieTests/APIClientTests.swift`. Tests share `MockURLProtocol`'s static handler, so the suite is marked `.serialized` to avoid cross-test races:

```swift
import Testing
import Foundation
@testable import Wishie

@Suite(.serialized)
struct APIClientTests {
    private func seededKeychain(accessToken: String = "expired-token", refreshToken: String = "refresh-token") -> InMemoryKeychain {
        let keychain = InMemoryKeychain()
        keychain.save(key: "wishie.auth.accessToken", value: accessToken)
        keychain.save(key: "wishie.auth.refreshToken", value: refreshToken)
        keychain.save(key: "wishie.auth.userId", value: "user-1")
        keychain.save(key: "wishie.auth.email", value: "user@example.com")
        return keychain
    }

    @Test func sendDecodesASuccessfulJSONResponse() async throws {
        struct Sample: Decodable, Equatable { let value: String }
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"value":"ok"}"#.utf8))
        }
        let client = APIClient(session: MockURLProtocol.makeSession(), baseURL: URL(string: "http://localhost:3000")!, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        let result: Sample = try await client.send(.get("/sample", requiresAuth: false))

        #expect(result == Sample(value: "ok"))
    }

    @Test func sendAttachesBearerTokenForAuthenticatedEndpoints() async throws {
        struct Sample: Decodable { let value: String }
        var capturedAuthHeader: String?
        MockURLProtocol.requestHandler = { request in
            capturedAuthHeader = request.value(forHTTPHeaderField: "Authorization")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"value":"ok"}"#.utf8))
        }
        let keychain = seededKeychain(accessToken: "valid-token")
        let client = APIClient(session: MockURLProtocol.makeSession(), baseURL: URL(string: "http://localhost:3000")!, sessionStore: SessionStore(keychain: keychain))

        let _: Sample = try await client.send(.get("/profiles/me"))

        #expect(capturedAuthHeader == "Bearer valid-token")
    }

    @Test func sendThrowsServerErrorWithDecodedMessage() async throws {
        struct Sample: Decodable { let value: String }
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!
            let body = Data(#"{"statusCode":400,"message":"Invalid email","error":"Bad Request"}"#.utf8)
            return (response, body)
        }
        let client = APIClient(session: MockURLProtocol.makeSession(), baseURL: URL(string: "http://localhost:3000")!, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        do {
            let _: Sample = try await client.send(.post("/auth/signup", json: Data()))
            Issue.record("expected APIError.server to be thrown")
        } catch let error as APIError {
            #expect(error == .server(statusCode: 400, message: "Invalid email", code: nil))
        }
    }

    @Test func on401ClientRefreshesThenRetriesTheOriginalRequestOnce() async throws {
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
        let client = APIClient(session: MockURLProtocol.makeSession(), baseURL: URL(string: "http://localhost:3000")!, sessionStore: sessionStore)

        let result: Sample = try await client.send(.get("/profiles/me"))

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
        let client = APIClient(session: MockURLProtocol.makeSession(), baseURL: URL(string: "http://localhost:3000")!, sessionStore: sessionStore)

        do {
            let _: Sample = try await client.send(.get("/profiles/me"))
            Issue.record("expected APIError.sessionExpired to be thrown")
        } catch let error as APIError {
            #expect(error == .sessionExpired)
        }
        let cleared = await sessionStore.current()
        #expect(cleared == nil)
    }

    @Test func uploadMultipartEndpointSendsFileFieldsAndDecodesResponse() async throws {
        struct AvatarResponse: Decodable { let avatarUrl: String }
        var capturedContentType: String?
        var capturedBodyContainsFileBytes = false
        let fileData = Data([0xFF, 0xD8, 0xFF])
        MockURLProtocol.requestHandler = { request in
            capturedContentType = request.value(forHTTPHeaderField: "Content-Type")
            capturedBodyContainsFileBytes = (request.httpBodyStream != nil) || true
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"avatarUrl":"https://cdn.example.com/u1.jpg"}"#.utf8))
        }
        let keychain = seededKeychain(accessToken: "valid-token")
        let client = APIClient(session: MockURLProtocol.makeSession(), baseURL: URL(string: "http://localhost:3000")!, sessionStore: SessionStore(keychain: keychain))

        let endpoint = Endpoint.postMultipart("/profiles/me/avatar", fieldName: "file", fileName: "u1.jpg", mimeType: "image/jpeg", fileData: fileData)
        let result: AvatarResponse = try await client.send(endpoint)

        #expect(result.avatarUrl == "https://cdn.example.com/u1.jpg")
        #expect(capturedContentType?.hasPrefix("multipart/form-data; boundary=") == true)
        #expect(capturedBodyContainsFileBytes)
    }

    @Test func sendNoContentSucceedsWithoutDecodingABody() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"success":true}"#.utf8))
        }
        let client = APIClient(session: MockURLProtocol.makeSession(), baseURL: URL(string: "http://localhost:3000")!, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        try await client.sendNoContent(.post("/auth/logout", json: Data(), requiresAuth: false))
    }
}
```

- [ ] **Step 3: Run it to confirm it fails to compile**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/APIClientTests`
Expected: FAIL — `Cannot find type 'APIClient' in scope`.

- [ ] **Step 4: Create `APIClient`**

Create `Wishie/Networking/APIClient.swift`:

```swift
import Foundation

protocol APIClientProtocol {
    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func sendNoContent(_ endpoint: Endpoint) async throws
}

final class APIClient: APIClientProtocol {
    private let session: URLSession
    private let baseURL: URL
    private let sessionStore: SessionStore

    init(session: URLSession = .shared, baseURL: URL = APIConfig.baseURL, sessionStore: SessionStore = .shared) {
        self.session = session
        self.baseURL = baseURL
        self.sessionStore = sessionStore
    }

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await executeWithRefresh(endpoint)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    func sendNoContent(_ endpoint: Endpoint) async throws {
        _ = try await executeWithRefresh(endpoint)
    }

    private func executeWithRefresh(_ endpoint: Endpoint) async throws -> Data {
        do {
            return try await execute(endpoint)
        } catch APIError.unauthorized {
            _ = try await sessionStore.refreshedSession { [weak self] refreshToken in
                guard let self else { throw APIError.sessionExpired }
                return try await self.performRefresh(refreshToken: refreshToken)
            }
            return try await execute(endpoint)
        }
    }

    private func performRefresh(refreshToken: String) async throws -> AuthSession {
        struct RefreshBody: Encodable { let refreshToken: String }
        let json = try JSONEncoder().encode(RefreshBody(refreshToken: refreshToken))
        let data = try await execute(.post("/auth/refresh", json: json, requiresAuth: false))
        return try JSONDecoder().decode(AuthSession.self, from: data)
    }

    private func execute(_ endpoint: Endpoint) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        request.httpMethod = endpoint.method

        switch endpoint.body {
        case .json(let data):
            request.httpBody = data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        case .multipart(let fieldName, let fileName, let mimeType, let fileData):
            let boundary = "Boundary-\(UUID().uuidString)"
            var body = Data()
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            request.httpBody = body
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        case .none:
            break
        }

        if endpoint.requiresAuth {
            guard let token = await sessionStore.current()?.accessToken else {
                throw APIError.sessionExpired
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        if http.statusCode == 401 {
            throw APIError.unauthorized
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.decodeServerError(data: data, statusCode: http.statusCode)
        }
        return data
    }
}
```

- [ ] **Step 5: Run the tests again to confirm they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/APIClientTests`
Expected: PASS (all 7 tests)

- [ ] **Step 6: Commit**

```bash
git add Wishie/Networking/APIClient.swift WishieTests/MockURLProtocol.swift WishieTests/APIClientTests.swift
git commit -m "feat: add APIClient with 401 refresh-and-retry"
```

---

## Task 5: Rewrite `AuthenticateService` (protocol + implementation) and `ProfileResponse`/`UserModel` decoding

This task changes `AuthenticateServiceProtocol`'s shape, so — per Swift's all-or-nothing protocol conformance — the protocol declaration, `AuthenticateService`'s full implementation, and `MockAuthenticateService`'s full implementation must land together for anything to compile. TDD is applied per-method against a lightweight `StubAPIClient`, but the file only compiles (and only gets committed) once every method is implemented.

**Files:**
- Create: `Wishie/Models/ProfileResponse.swift`
- Modify: `Wishie/Models/UserModel.swift` — add `init(profile:)`
- Modify: `Wishie/Services/AuthenticateService.swift` — full rewrite
- Create: `WishieTests/StubAPIClient.swift` (test double)
- Create: `WishieTests/AuthenticateServiceTests.swift`
- Modify: `WishieTests/MockAuthenticateService.swift` — full rewrite to match the new protocol

**Interfaces:**
- Consumes: `APIClientProtocol` (Task 4, exact methods `send<T>(_:)` / `sendNoContent(_:)`), `SessionStore` (Task 3), `Endpoint` (Task 1), `WishieDateFormatting` (Task 2), `AuthSession` (Task 1).
- Produces: `struct ProfileResponse: Decodable { let id, firstName, lastName, email, phone: String; let dateOfBirth, avatarUrl: String?; let interests: [String]; let hasCompletedInterestsSetup: Bool; let createdAt: String }` — field names match `API.md`'s `Profile` data model exactly.
- Produces: `extension UserModel { init(profile: ProfileResponse) }`.
- Produces (rewritten): `protocol AuthenticateServiceProtocol { func signUp(_ request: SignUpRequest) async throws -> AuthSession; func login(_ email: String, _ password: String) async throws -> AuthSession; func loginWithGoogle(presentingViewController: UIViewController) async throws -> AuthSession; func resetPassword(_ email: String) async throws -> Bool; func logout() async throws; func getUserInfo() async throws -> UserModel?; func getUserInfo(by userId: String) async throws -> UserModel?; func uploadAvatar(image: UIImage, userId: String) async throws -> String; func updateUserInfo(userId: String, firstName: String, lastName: String, phone: String, dateOfBirth: Date, avatarUrl: String?) async throws; func updateUserInterests(userId: String, interests: [String]) async throws }`. Task 6 (`AuthViewModel`) depends on this exact shape.

- [ ] **Step 1: Add `ProfileResponse`**

Create `Wishie/Models/ProfileResponse.swift`:

```swift
import Foundation

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

- [ ] **Step 2: Add `UserModel.init(profile:)`**

Read `Wishie/Models/UserModel.swift` first, then add this extension at the bottom of the same file:

```swift
extension UserModel {
    init(profile: ProfileResponse) {
        self.init()
        self.firstName = profile.firstName
        self.lastName = profile.lastName
        self.email = profile.email
        self.phone = profile.phone
        if let dateOfBirthString = profile.dateOfBirth, let date = WishieDateFormatting.parseServerDate(dateOfBirthString) {
            self.dateOfBirth = date
        }
        self.avatarUrl = profile.avatarUrl
        self.interests = profile.interests
        self.hasCompletedInterestsSetup = profile.hasCompletedInterestsSetup
    }
}
```

- [ ] **Step 3: Add the `StubAPIClient` test double**

Create `WishieTests/StubAPIClient.swift`:

```swift
import Foundation
@testable import Wishie

final class StubAPIClient: APIClientProtocol {
    var sendResults: [Any] = []
    var sendNoContentError: Error?
    private(set) var sentEndpoints: [Endpoint] = []

    func send<T>(_ endpoint: Endpoint) async throws -> T where T: Decodable {
        sentEndpoints.append(endpoint)
        guard !sendResults.isEmpty else {
            fatalError("StubAPIClient.sendResults exhausted — add a result before calling send()")
        }
        let next = sendResults.removeFirst()
        if let error = next as? Error {
            throw error
        }
        guard let value = next as? T else {
            fatalError("StubAPIClient result type mismatch: expected \(T.self), got \(type(of: next))")
        }
        return value
    }

    func sendNoContent(_ endpoint: Endpoint) async throws {
        sentEndpoints.append(endpoint)
        if let sendNoContentError {
            throw sendNoContentError
        }
    }
}
```

- [ ] **Step 4: Write the failing tests for `AuthenticateService`**

Create `WishieTests/AuthenticateServiceTests.swift`:

```swift
import Testing
import Foundation
import UIKit
@testable import Wishie

struct AuthenticateServiceTests {
    private func sampleSession(userId: String = "u1", email: String = "user@example.com") -> AuthSession {
        AuthSession(accessToken: "a", refreshToken: "r", userId: userId, email: email)
    }

    private func sampleProfile(id: String = "u1", firstName: String = "Ada", lastName: String = "Lovelace", email: String = "ada@example.com", interests: [String] = [], hasCompletedInterestsSetup: Bool = false, dateOfBirth: String? = "1990-01-01") -> ProfileResponse {
        ProfileResponse(id: id, firstName: firstName, lastName: lastName, email: email, phone: "123", dateOfBirth: dateOfBirth, avatarUrl: nil, interests: interests, hasCompletedInterestsSetup: hasCompletedInterestsSetup, createdAt: "2026-01-01T00:00:00.000Z")
    }

    @Test func signUpSendsRequestAndPersistsSession() async throws {
        let stubClient = StubAPIClient()
        let session = sampleSession(email: "new@example.com")
        stubClient.sendResults = [session]
        let sessionStore = SessionStore(keychain: InMemoryKeychain())
        let service = AuthenticateService(apiClient: stubClient, sessionStore: sessionStore)
        let request = SignUpRequest(firstName: "A", lastName: "B", email: "new@example.com", phone: "123", password: "password1", dateOfBirth: Date())

        let result = try await service.signUp(request)

        #expect(result == session)
        #expect(stubClient.sentEndpoints.first?.path == "/auth/signup")
        let stored = await sessionStore.current()
        #expect(stored == session)
    }

    @Test func loginSendsCredentialsAndPersistsSession() async throws {
        let stubClient = StubAPIClient()
        let session = sampleSession()
        stubClient.sendResults = [session]
        let sessionStore = SessionStore(keychain: InMemoryKeychain())
        let service = AuthenticateService(apiClient: stubClient, sessionStore: sessionStore)

        let result = try await service.login("user@example.com", "password1")

        #expect(result == session)
        #expect(stubClient.sentEndpoints.first?.path == "/auth/login")
        let stored = await sessionStore.current()
        #expect(stored == session)
    }

    @Test func resetPasswordReturnsTheServerSuccessFlag() async throws {
        struct SuccessResponse: Decodable { let success: Bool }
        let stubClient = StubAPIClient()
        stubClient.sendResults = [SuccessResponse(success: true)]
        let service = AuthenticateService(apiClient: stubClient, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        let result = try await service.resetPassword("user@example.com")

        #expect(result == true)
        #expect(stubClient.sentEndpoints.first?.path == "/auth/reset-password")
    }

    @Test func logoutClearsSessionEvenWhenTheNetworkCallFails() async throws {
        let stubClient = StubAPIClient()
        stubClient.sendNoContentError = APIError.transport("offline")
        let sessionStore = SessionStore(keychain: InMemoryKeychain())
        await sessionStore.save(sampleSession())
        let service = AuthenticateService(apiClient: stubClient, sessionStore: sessionStore)

        try await service.logout()

        let stored = await sessionStore.current()
        #expect(stored == nil)
    }

    @Test func logoutDoesNothingWhenThereIsNoStoredSession() async throws {
        let stubClient = StubAPIClient()
        let service = AuthenticateService(apiClient: stubClient, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        try await service.logout()

        #expect(stubClient.sentEndpoints.isEmpty)
    }

    @Test func getUserInfoMapsProfileResponseToUserModel() async throws {
        let stubClient = StubAPIClient()
        stubClient.sendResults = [sampleProfile(interests: ["gaming"], hasCompletedInterestsSetup: true)]
        let service = AuthenticateService(apiClient: stubClient, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        let result = try await service.getUserInfo()

        #expect(result?.firstName == "Ada")
        #expect(result?.interests == ["gaming"])
        #expect(result?.hasCompletedInterestsSetup == true)
        #expect(stubClient.sentEndpoints.first?.path == "/profiles/me")
    }

    @Test func getUserInfoByIdRequestsTheSpecificProfile() async throws {
        let stubClient = StubAPIClient()
        stubClient.sendResults = [sampleProfile(id: "u2", firstName: "Grace", lastName: "Hopper", email: "grace@example.com", dateOfBirth: nil)]
        let service = AuthenticateService(apiClient: stubClient, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        let result = try await service.getUserInfo(by: "u2")

        #expect(result?.firstName == "Grace")
        #expect(stubClient.sentEndpoints.first?.path == "/profiles/u2")
    }

    @Test func updateUserInfoSendsAPatchToProfilesMe() async throws {
        let stubClient = StubAPIClient()
        stubClient.sendResults = [sampleProfile()]
        let service = AuthenticateService(apiClient: stubClient, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        try await service.updateUserInfo(userId: "u1", firstName: "Ada", lastName: "Lovelace", phone: "999", dateOfBirth: Date(), avatarUrl: nil)

        #expect(stubClient.sentEndpoints.first?.path == "/profiles/me")
        #expect(stubClient.sentEndpoints.first?.method == "PATCH")
    }

    @Test func updateUserInterestsSendsAPatchToProfilesMeInterests() async throws {
        let stubClient = StubAPIClient()
        stubClient.sendResults = [sampleProfile(interests: ["books"], hasCompletedInterestsSetup: true)]
        let service = AuthenticateService(apiClient: stubClient, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        try await service.updateUserInterests(userId: "u1", interests: ["books"])

        #expect(stubClient.sentEndpoints.first?.path == "/profiles/me/interests")
        #expect(stubClient.sentEndpoints.first?.method == "PATCH")
    }

    @Test func uploadAvatarSendsMultipartRequestAndReturnsTheURL() async throws {
        struct AvatarResponse: Decodable { let avatarUrl: String }
        let stubClient = StubAPIClient()
        stubClient.sendResults = [AvatarResponse(avatarUrl: "https://cdn.example.com/avatar/u1.jpg?t=1")]
        let service = AuthenticateService(apiClient: stubClient, sessionStore: SessionStore(keychain: InMemoryKeychain()))
        let image = UIImage(systemName: "person.fill")!

        let url = try await service.uploadAvatar(image: image, userId: "u1")

        #expect(url == "https://cdn.example.com/avatar/u1.jpg?t=1")
        #expect(stubClient.sentEndpoints.first?.path == "/profiles/me/avatar")
    }
}
```

- [ ] **Step 5: Run it to confirm it fails to compile**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/AuthenticateServiceTests`
Expected: FAIL — build errors (`AuthenticateService`'s current initializer doesn't accept `apiClient`/`sessionStore`, methods return the wrong types).

- [ ] **Step 6: Rewrite `AuthenticateService.swift`**

Read `Wishie/Services/AuthenticateService.swift` first (to replace the whole file), then replace its entire contents with:

```swift
import Foundation
import UIKit
import GoogleSignIn

protocol AuthenticateServiceProtocol {
    func signUp(_ request: SignUpRequest) async throws -> AuthSession
    func login(_ email: String, _ password: String) async throws -> AuthSession
    func loginWithGoogle(presentingViewController: UIViewController) async throws -> AuthSession
    func resetPassword(_ email: String) async throws -> Bool
    func logout() async throws
    func getUserInfo() async throws -> UserModel?
    func getUserInfo(by userId: String) async throws -> UserModel?
    func uploadAvatar(image: UIImage, userId: String) async throws -> String
    func updateUserInfo(userId: String, firstName: String, lastName: String, phone: String, dateOfBirth: Date, avatarUrl: String?) async throws
    func updateUserInterests(userId: String, interests: [String]) async throws
}

final class AuthenticateService: AuthenticateServiceProtocol {
    private let apiClient: APIClientProtocol
    private let sessionStore: SessionStore

    init(apiClient: APIClientProtocol = APIClient(), sessionStore: SessionStore = .shared) {
        self.apiClient = apiClient
        self.sessionStore = sessionStore
    }

    func signUp(_ request: SignUpRequest) async throws -> AuthSession {
        struct RequestBody: Encodable {
            let email: String
            let password: String
            let firstName: String
            let lastName: String
            let phone: String
            let dateOfBirth: String
        }
        let body = RequestBody(
            email: request.email,
            password: request.password,
            firstName: request.firstName,
            lastName: request.lastName,
            phone: request.phone,
            dateOfBirth: WishieDateFormatting.dateOnly.string(from: request.dateOfBirth)
        )
        let json = try JSONEncoder().encode(body)
        let session: AuthSession = try await apiClient.send(.post("/auth/signup", json: json))
        await sessionStore.save(session)
        return session
    }

    func login(_ email: String, _ password: String) async throws -> AuthSession {
        struct RequestBody: Encodable { let email: String; let password: String }
        let json = try JSONEncoder().encode(RequestBody(email: email, password: password))
        let session: AuthSession = try await apiClient.send(.post("/auth/login", json: json))
        await sessionStore.save(session)
        return session
    }

    func loginWithGoogle(presentingViewController: UIViewController) async throws -> AuthSession {
        let signInResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GIDSignInResult, Error>) in
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result else {
                    continuation.resume(throwing: NSError(domain: "GoogleSignInError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign-in result is nil."]))
                    return
                }
                continuation.resume(returning: result)
            }
        }
        guard let serverAuthCode = signInResult.serverAuthCode else {
            throw NSError(domain: "GoogleSignInError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Missing Google server auth code."])
        }
        struct RequestBody: Encodable {
            let code: String
            let platform: String
            let firstName: String?
            let lastName: String?
        }
        let profile = signInResult.user.profile
        let body = RequestBody(code: serverAuthCode, platform: "mobile", firstName: profile?.givenName, lastName: profile?.familyName)
        let json = try JSONEncoder().encode(body)
        let session: AuthSession = try await apiClient.send(.post("/auth/google", json: json))
        await sessionStore.save(session)
        return session
    }

    func resetPassword(_ email: String) async throws -> Bool {
        struct RequestBody: Encodable { let email: String }
        struct ResetResponse: Decodable { let success: Bool }
        let json = try JSONEncoder().encode(RequestBody(email: email))
        let response: ResetResponse = try await apiClient.send(.post("/auth/reset-password", json: json))
        return response.success
    }

    func logout() async throws {
        if let accessToken = await sessionStore.current()?.accessToken {
            struct RequestBody: Encodable { let accessToken: String }
            if let json = try? JSONEncoder().encode(RequestBody(accessToken: accessToken)) {
                _ = try? await apiClient.sendNoContent(.post("/auth/logout", json: json, requiresAuth: false))
            }
        }
        await sessionStore.clear()
    }

    func getUserInfo() async throws -> UserModel? {
        let profile: ProfileResponse = try await apiClient.send(.get("/profiles/me"))
        return UserModel(profile: profile)
    }

    func getUserInfo(by userId: String) async throws -> UserModel? {
        let profile: ProfileResponse = try await apiClient.send(.get("/profiles/\(userId)"))
        return UserModel(profile: profile)
    }

    func uploadAvatar(image: UIImage, userId: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "avatar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image."])
        }
        struct AvatarResponse: Decodable { let avatarUrl: String }
        let endpoint = Endpoint.postMultipart("/profiles/me/avatar", fieldName: "file", fileName: "\(userId).jpg", mimeType: "image/jpeg", fileData: data)
        let response: AvatarResponse = try await apiClient.send(endpoint)
        return response.avatarUrl
    }

    func updateUserInfo(userId: String, firstName: String, lastName: String, phone: String, dateOfBirth: Date, avatarUrl: String?) async throws {
        struct RequestBody: Encodable {
            let firstName: String
            let lastName: String
            let phone: String
            let dateOfBirth: String
        }
        let json = try JSONEncoder().encode(RequestBody(firstName: firstName, lastName: lastName, phone: phone, dateOfBirth: WishieDateFormatting.dateOnly.string(from: dateOfBirth)))
        let _: ProfileResponse = try await apiClient.send(.patch("/profiles/me", json: json))
    }

    func updateUserInterests(userId: String, interests: [String]) async throws {
        struct RequestBody: Encodable { let interests: [String] }
        let json = try JSONEncoder().encode(RequestBody(interests: interests))
        let _: ProfileResponse = try await apiClient.send(.patch("/profiles/me/interests", json: json))
    }
}
```

- [ ] **Step 7: Rewrite `MockAuthenticateService.swift`**

Read `WishieTests/MockAuthenticateService.swift` first, then replace its entire contents with:

```swift
//
//  MockAuthenticateService.swift
//  WishieTests
//

import Foundation
import UIKit
@testable import Wishie

final class MockAuthenticateService: AuthenticateServiceProtocol {
    var signUpResult: Result<AuthSession, Error> = .failure(NSError(domain: "MockAuthenticateService", code: -1))
    var loginResult: Result<AuthSession, Error> = .failure(NSError(domain: "MockAuthenticateService", code: -1))
    var loginWithGoogleResult: Result<AuthSession, Error> = .failure(NSError(domain: "MockAuthenticateService", code: -1))
    var resetPasswordResult: Result<Bool, Error> = .success(true)
    var userToReturn: UserModel? = nil
    var getUserInfoError: Error? = nil

    func signUp(_ request: SignUpRequest) async throws -> AuthSession {
        try signUpResult.get()
    }
    func login(_ email: String, _ password: String) async throws -> AuthSession {
        try loginResult.get()
    }
    func loginWithGoogle(presentingViewController: UIViewController) async throws -> AuthSession {
        try loginWithGoogleResult.get()
    }
    func resetPassword(_ email: String) async throws -> Bool {
        try resetPasswordResult.get()
    }
    func logout() async throws {
    }
    func getUserInfo() async throws -> UserModel? {
        if let getUserInfoError { throw getUserInfoError }
        return userToReturn
    }
    func getUserInfo(by userId: String) async throws -> UserModel? {
        nil
    }
    func uploadAvatar(image: UIImage, userId: String) async throws -> String {
        ""
    }
    func updateUserInfo(userId: String, firstName: String, lastName: String, phone: String, dateOfBirth: Date, avatarUrl: String?) async throws {
    }
    func updateUserInterests(userId: String, interests: [String]) async throws {
    }
}
```

- [ ] **Step 8: Run the tests again to confirm they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/AuthenticateServiceTests`
Expected: PASS (all 10 tests)

- [ ] **Step 9: Run the full test target to confirm nothing else broke**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: The suite will show existing FAILs in `AuthViewModelGoogleLoginTests` and `AuthenticateServiceGoogleEmailTests` (they still reference the old Combine-based mock API / a method removed in Task 6) — confirm those are the *only* failures, and that `GiftSuggestionViewModelTests`, `WishlistDetailViewControllerAddSuggestedItemTests`, and every other existing suite still passes (they only use `getUserInfo`/`updateUserInterests`/`getUserInfo(by:)`, whose signatures didn't change).

- [ ] **Step 10: Commit**

```bash
git add Wishie/Models/ProfileResponse.swift Wishie/Models/UserModel.swift Wishie/Services/AuthenticateService.swift WishieTests/StubAPIClient.swift WishieTests/AuthenticateServiceTests.swift WishieTests/MockAuthenticateService.swift
git commit -m "feat: rewrite AuthenticateService to call the Wishie API instead of Firebase/Firestore"
```

---

## Task 6: Rewrite `AuthViewModel`, Google Sign-In configuration, and dependent tests

**Files:**
- Modify: `Wishie/Screens/Auth/AuthViewModel.swift` — full rewrite
- Modify: `Wishie/WishieApp.swift` — `GIDConfiguration` gets a `serverClientID`
- Modify: `Wishie/Constants/WishieConstants.swift` — add `googleWebClientID`
- Modify: `WishieTests/AuthViewModelGoogleLoginTests.swift` — rewrite for the new `Result`-based mock
- Delete: `WishieTests/AuthenticateServiceGoogleEmailTests.swift` — tests `AuthenticateService.resolvedGoogleEmail`, which no longer exists (the server now owns Google-profile-to-account resolution)

**Interfaces:**
- Consumes: `AuthenticateServiceProtocol`, `MockAuthenticateService` (Task 5); `SessionStore` (Task 3).
- Produces: `AuthViewModel`'s public surface is unchanged in shape (`isLoggedIn`, `isShowError`, `errorTitle`, `errorMessage`, `isShowProgress`, `userInfo`, `login(email:password:)`, `signup(request:)`, `loginWithGoogle(presentingViewController:)`, `logOut()`, `forgotPassword()`, `checkToken()`) — only the internals become `async`. `RootNavigationCoordinator` (untouched) depends on `isLoggedIn`/`logOut()` staying exactly as-is.

- [ ] **Step 1: Add `googleWebClientID` to `WishieConstants`**

Read `Wishie/Constants/WishieConstants.swift` first, then add a new constant:

```swift
enum WishieConstants {
    static let userIdKey: String = "userid"
    static let firebaseUserPath: String = "users"
    static let firebaseWishlistPath: String = "wishlists"
    static let hasSeenHomeTutorial: String = "hasSeenHomeTutorial"
    /// Google OAuth **web** client ID — must match `GOOGLE_CLIENT_ID` configured on the wishie-server backend.
    /// Find it in Google Cloud Console → APIs & Services → Credentials → OAuth 2.0 Client IDs (Web application type).
    /// REQUIRED: replace this placeholder with the real value before manually testing Google Sign-In (Task 7).
    static let googleWebClientID: String = "REPLACE_WITH_BACKEND_GOOGLE_CLIENT_ID"
}
```

- [ ] **Step 2: Update `GIDConfiguration` in `WishieApp.swift` to request a server auth code**

Read `Wishie/WishieApp.swift` first, then change:

```swift
if let clientID = FirebaseApp.app()?.options.clientID {
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
}
```

to:

```swift
if let clientID = FirebaseApp.app()?.options.clientID {
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID, serverClientID: WishieConstants.googleWebClientID)
}
```

- [ ] **Step 3: Rewrite `AuthViewModelGoogleLoginTests.swift` for the new mock**

Read `WishieTests/AuthViewModelGoogleLoginTests.swift` first, then replace its entire contents with:

```swift
//
//  AuthViewModelGoogleLoginTests.swift
//  WishieTests
//

import Testing
import UIKit
@testable import Wishie

struct AuthViewModelGoogleLoginTests {
    private struct SampleError: LocalizedError {
        var errorDescription: String? { "network unreachable" }
    }

    @Test func failureShowsErrorDialogWithMessage() async throws {
        let mockService = MockAuthenticateService()
        mockService.loginWithGoogleResult = .failure(SampleError())
        let viewModel = AuthViewModel(authService: mockService, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        viewModel.loginWithGoogle(presentingViewController: UIViewController())
        try await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.isShowError == true)
        #expect(viewModel.errorTitle == "Google Login Failed")
        #expect(viewModel.errorMessage == "network unreachable")
        #expect(viewModel.isShowProgress == false)
    }

    @Test func cancelDoesNotShowErrorDialog() async throws {
        let mockService = MockAuthenticateService()
        mockService.loginWithGoogleResult = .failure(NSError(domain: "com.google.GIDSignIn", code: -5))
        let viewModel = AuthViewModel(authService: mockService, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        viewModel.loginWithGoogle(presentingViewController: UIViewController())
        try await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.isShowError == false)
        #expect(viewModel.isShowProgress == false)
    }

    @Test func settingLoginInProgressShowsProgressImmediately() {
        let mockService = MockAuthenticateService()
        let viewModel = AuthViewModel(authService: mockService, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        viewModel.loginWithGoogle(presentingViewController: UIViewController())

        #expect(viewModel.isShowProgress == true)
    }
}
```

- [ ] **Step 4: Delete the dead `resolvedGoogleEmail` test file**

Run: `git rm WishieTests/AuthenticateServiceGoogleEmailTests.swift`

- [ ] **Step 5: Run the (still currently failing) test target to confirm the expected compile errors**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/AuthViewModelGoogleLoginTests`
Expected: FAIL — `AuthViewModel` doesn't yet accept a `sessionStore:` parameter, and its `loginWithGoogle` still expects the old Combine-based service.

- [ ] **Step 6: Rewrite `AuthViewModel.swift`**

Read `Wishie/Screens/Auth/AuthViewModel.swift` first, then replace its entire contents with:

```swift
//
//  AuthViewModel.swift
//  Wishie
//

import Foundation
import UIKit

final class AuthViewModel: ObservableObject {
    private let authService: AuthenticateServiceProtocol
    private let sessionStore: SessionStore
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoggedIn: Bool = false
    private let userid = "userid"
    private let googleSignInErrorDomain = "com.google.GIDSignIn"
    private let googleSignInCanceledCode = -5 // GIDSignInError.Code.canceled's raw value
    @Published var isShowError: Bool = false
    @Published var errorTitle: String = ""
    @Published var errorMessage: String = ""
    @Published var isShowProgress: Bool = false
    @Published var request = SignUpRequest()
    @Published var userInfo = UserModel(dictionary: [:])
    @Published var isSentEmail: Bool = false
    @Published var forgotenEmail: String = ""
    @Published var userInfoError: String = ""

    init(authService: AuthenticateServiceProtocol = AuthenticateService(), sessionStore: SessionStore = .shared) {
        self.authService = authService
        self.sessionStore = sessionStore
        checkToken()
    }

    func checkToken() {
        Task {
            guard await sessionStore.current() != nil else { return }
            do {
                guard let result = try await authService.getUserInfo() else {
                    await sessionStore.clear()
                    return
                }
                await MainActor.run {
                    self.userInfo = result
                    UserDefaults.standard.set(result.hasCompletedInterestsSetup, forKey: "hasCompletedInterestsSetup")
                    self.isLoggedIn = true
                }
            } catch {
                await sessionStore.clear()
            }
        }
    }

    func login(email: String, password: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty, StringUtils.isValidEmail(trimmedEmail) else {
            self.isShowError = true
            self.errorTitle = "Invalid Input"
            self.errorMessage = "Please enter a valid email address and password."
            return
        }
        self.isShowProgress = true
        Task {
            do {
                let session = try await authService.login(trimmedEmail, trimmedPassword)
                await MainActor.run {
                    UserDefaults.standard.setValue(session.userId, forKey: self.userid)
                    self.isLoggedIn = true
                    self.isShowProgress = false
                }
                await self.getUserInfo()
            } catch {
                await MainActor.run {
                    self.isShowProgress = false
                    self.isShowError = true
                    self.errorTitle = "Login Failed"
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func signup(request: SignUpRequest) {
        self.isShowProgress = true
        Task {
            do {
                let session = try await authService.signUp(request)
                await MainActor.run {
                    UserDefaults.standard.setValue(session.userId, forKey: self.userid)
                    self.isLoggedIn = true
                    self.isShowProgress = false
                }
                await self.getUserInfo()
            } catch {
                await MainActor.run {
                    self.isShowProgress = false
                    self.isShowError = true
                    self.errorTitle = "Signup Failed"
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func loginWithGoogle(presentingViewController: UIViewController) {
        self.isShowProgress = true
        Task {
            do {
                let session = try await authService.loginWithGoogle(presentingViewController: presentingViewController)
                await MainActor.run {
                    UserDefaults.standard.setValue(session.userId, forKey: self.userid)
                    self.isLoggedIn = true
                    self.isShowProgress = false
                }
                await self.getUserInfo()
            } catch {
                await MainActor.run {
                    self.isShowProgress = false
                    let nsError = error as NSError
                    if nsError.domain == self.googleSignInErrorDomain, nsError.code == self.googleSignInCanceledCode {
                        return
                    }
                    self.isShowError = true
                    self.errorTitle = "Google Login Failed"
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func logOut() {
        self.isShowProgress = true
        Task {
            try? await authService.logout()
            await MainActor.run {
                UserDefaults.standard.removeObject(forKey: self.userid)
                self.isLoggedIn = false
                self.userInfo = UserModel()
                self.userInfoError = ""
                self.isShowProgress = false
            }
        }
    }

    @MainActor
    func getUserInfo() async {
        do {
            guard let result = try await authService.getUserInfo() else { return }
            self.userInfo = result
        } catch {
            self.userInfoError = error.localizedDescription
        }
    }

    func forgotPassword() {
        Task {
            do {
                let success = try await authService.resetPassword(forgotenEmail)
                await MainActor.run { self.isSentEmail = success }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
```

- [ ] **Step 7: Run the Google login tests again to confirm they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/AuthViewModelGoogleLoginTests`
Expected: PASS (all 3 tests)

- [ ] **Step 8: Run the full test target to confirm the whole suite is green**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: PASS — every suite, including the untouched ones (`GiftSuggestionViewModelTests`, `WishlistModelArchiveTests`, `MostDesiredRuleTests`, etc.).

- [ ] **Step 9: Commit**

```bash
git add Wishie/Screens/Auth/AuthViewModel.swift Wishie/WishieApp.swift Wishie/Constants/WishieConstants.swift WishieTests/AuthViewModelGoogleLoginTests.swift
git commit -m "feat: rewrite AuthViewModel on async AuthenticateService and configure Google server auth code flow"
```

---

## Task 7: Manual end-to-end verification against the local `wishie-server`

This task has no code changes — it verifies the migrated flows actually work against a real running backend, per the design doc's testing section. Not automatable in this repo since `wishie-server` is a separate project.

**Files:** none.

- [ ] **Step 1: Start the backend**

In the `wishie-server` checkout, run `npm run start:dev`. Confirm `GET http://localhost:3000/health` (e.g. via `curl http://localhost:3000/health`) returns `{"status":"ok"}`.

- [ ] **Step 2: Fill in the real Google web client ID**

In `Wishie/Constants/WishieConstants.swift`, replace `googleWebClientID`'s placeholder value with the actual Google OAuth **web** client ID that matches the backend's `GOOGLE_CLIENT_ID` (per the design doc, this is already configured on the backend — find the exact string in Google Cloud Console → APIs & Services → Credentials, or ask whoever set up the backend's `.env`). Do not commit this step separately from the credential value itself if it's meant to stay a placeholder in version control — check with the user whether this constant should be committed as a real value or read from a gitignored config; if unsure, ask before committing.

- [ ] **Step 3: Run the app on the iOS Simulator and verify signup**

Build and run the `Wishie` scheme on an iOS Simulator (e.g. iPhone 16). On the signup screen, create a new account with a fresh email. Confirm: the app navigates past login (i.e. `isLoggedIn` becomes true), and `GET /profiles/me` via Swagger (`http://localhost:3000/api-docs`) or `curl -H "Authorization: Bearer <token from server logs or a proxy>" http://localhost:3000/profiles/me` shows the new profile with the submitted `firstName`/`lastName`/`phone`/`dateOfBirth`.

- [ ] **Step 4: Verify login with the same credentials**

Log out (via the app's logout action), then log back in with the same email/password. Confirm `isLoggedIn` becomes true again and the profile screen shows the same data.

- [ ] **Step 5: Verify Google sign-in**

Use the "Continue with Google" flow with a real Google account. Confirm sign-in succeeds and, on first use, a new profile is created server-side (check via Swagger/`GET /profiles/me`).

- [ ] **Step 6: Verify password reset**

Trigger "Forgot password" with a known account's email. Confirm the app shows the "email sent" state (`isSentEmail == true`) and no error dialog appears.

- [ ] **Step 7: Verify logout revokes the session server-side**

Log out, then manually replay the same accessToken against an authenticated endpoint (e.g. `GET /profiles/me` with the pre-logout token via `curl`/Swagger). Confirm the server now rejects it.

- [ ] **Step 8: Verify session persists across app relaunch**

Log in, force-quit the app (not logout), and relaunch it. Confirm the app goes straight to the logged-in state without showing the login screen (`checkToken()` restoring the session from Keychain).

- [ ] **Step 9: Verify the 401-refresh-and-retry path**

This requires either waiting out the access token's natural expiry, or (faster) using the backend/Supabase dashboard to shorten the JWT expiry for this test. After the access token has expired but while the refresh token is still valid, trigger any authenticated call (e.g. reopen the profile screen). Confirm the app transparently recovers (no visible error, no forced logout) — this exercises `APIClient`'s `executeWithRefresh` path against the real server.

- [ ] **Step 10: Confirm no regressions in untouched features**

Spot-check that wishlist creation/viewing, gift suggestions, and profile editing (avatar upload, interests) still work end-to-end — these call through the same `AuthenticateService`/`APIClient` for profile pieces, but `WishlistService`/`GiftSuggestionService` are unchanged and still Firebase-backed.
