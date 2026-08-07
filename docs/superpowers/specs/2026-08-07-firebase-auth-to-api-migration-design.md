# Firebase Auth → Wishie API Migration — Design

## Context

Wishie's iOS app currently authenticates through `FirebaseAuth` (email/password + Google sign-in) and stores the user's profile as a Firestore document (`users/{uid}`). A NestJS backend (`wishie-server`, documented in `API.md`) now exists with working `/auth/*` and `/profiles/*` endpoints, backed by Supabase Auth + Postgres. There is no production deployment yet — the server runs locally (`npm run start:dev`, port 3000).

`AuthenticateService`/`AuthenticateServiceProtocol` currently bundles two concerns: pure auth (login, signup, Google sign-in, password reset) and profile CRUD (`getUserInfo`, `updateUserInfo`, `uploadAvatar`, `updateUserInterests`), all Firestore-backed. Because a user created via the new API gets a Postgres `Profile` row — not a Firestore document — migrating only the login/signup calls while leaving profile CRUD on Firestore would break immediately for any new account (no Firestore doc to read). This design therefore migrates the whole `AuthenticateService` unit, not just login/signup.

No iOS networking layer exists yet (no `URLSession`/Alamofire client) — this is also the first piece of that infrastructure, built to be reused by `WishlistService`/`GiftSuggestionService` when they migrate later (out of scope here; see `2026-07-25-nestjs-backend-migration-design.md`).

## Goal

Replace `AuthenticateService`'s Firebase/Firestore/Supabase-Storage internals with HTTP calls to the Wishie API's `/auth/*` and `/profiles/*` endpoints, while keeping `AuthenticateServiceProtocol`'s call sites (Auth, Profile, EditProfile, Interests, GiftSuggestions screens) working with minimal changes. Firebase/Firestore usage elsewhere in the app (wishlists, gift suggestions Cloud Function) is untouched.

## Approach

### Networking & session layer (new)

A new `Wishie/Networking/` group:

- **`APIConfig`** — `baseURL` selected via `#if targetEnvironment(simulator)`: `http://localhost:3000` on Simulator, a `deviceLANIP`-based constant on device builds (matching `API.md`'s guidance that the LAN IP changes per Wi-Fi network — updated by hand when it does). Physical-device testing also needs the debug-only ATS exception (`NSAllowsArbitraryLoads`) in `Info.plist`, per `API.md`.
- **`APIClient`** — `URLSession`-based, one generic `send<T: Decodable>(_ endpoint: Endpoint) async throws -> T`. `Endpoint` carries path, method, body, and whether the call requires auth. Encodes/decodes JSON; decodes both API error shapes (`{statusCode,message,error}` and the refresh/logout `{statusCode,code,message}` variant) into an `APIError` enum, including a distinguishable case for `AUTH_REFRESH_TOKEN_INVALID`.
- **`SessionStore`** (actor) — owns `AuthSession { accessToken, refreshToken, userId, email }`, persisted via the existing `KeychainManager`. `current()` loads from Keychain and caches in memory; `save(_:)`/`clear()` write/delete; `refreshedSession(using:)` calls `POST /auth/refresh` and persists the rotated token pair. Actor isolation single-flights concurrent refresh attempts.

**Request flow:** `APIClient` attaches `Authorization: Bearer <token>` from `SessionStore` on authenticated endpoints. On a `401`, it calls `SessionStore.refreshedSession()` and retries the original request once. If the refresh itself fails, `APIClient` throws `APIError.sessionExpired`, `SessionStore` is cleared, and the error propagates to `AuthViewModel`, which flips `isLoggedIn = false`. This makes refresh transparent to every caller and is the pattern later services (`WishlistService`, etc.) will reuse.

### `AuthenticateServiceProtocol` (rewritten, fully async/await)

```swift
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
```

Mapped directly to endpoints: `POST /auth/signup`, `/login`, `/google`, `/reset-password`, `/logout`, `GET /profiles/me`, `GET /profiles/:id`, `POST /profiles/me/avatar` (multipart), `PATCH /profiles/me`, `PATCH /profiles/me/interests`. `signUp`/`login`/`loginWithGoogle` persist the returned session via `SessionStore.save(_:)`. `logout()` calls `POST /auth/logout` best-effort (a network failure doesn't block it) and always clears `SessionStore` locally.

Dropping the Combine (`AnyPublisher<FirebaseAuth.AuthDataResult?, Error>`) signatures on `login`/`signUp`/`loginWithGoogle`/`resetPassword` is intentional — `AuthDataResult` is a Firebase type with no equivalent once Firebase Auth is gone, and the rest of the protocol (`getUserInfo`, etc.) is already async, so this unifies the whole protocol on one calling convention.

### Google Sign-In

`API.md`'s `POST /auth/google` requires a Google **authorization code**, not an ID token — a different flow than today's `idToken`-based one. `WishieApp.swift` currently configures `GIDSignIn` with only the Firebase iOS client ID (`GIDConfiguration(clientID:)`). This changes to `GIDConfiguration(clientID: iosClientID, serverClientID: webClientID)`, where `webClientID` matches the backend's `GOOGLE_CLIENT_ID` (already configured on the backend, per user confirmation). `loginWithGoogle` reads `signInResult.serverAuthCode` (requested with `openid email profile` scope) instead of `idToken`, and calls `POST /auth/google` with `{ code, platform: "mobile" }`.

### `AuthViewModel`

Methods become `Task { do { ... } catch { ... } }` wrappers around the async service calls, replacing the current `.sink` subscriptions — same published `isShowError`/`errorTitle`/`errorMessage`/`isShowProgress` properties, so screens (`LoginView`, `SignUpView`, etc.) don't change. `checkToken()` becomes: if `SessionStore` has a persisted session, call `getUserInfo()`; success sets `isLoggedIn = true`; failure (including `APIClient`'s own refresh-and-fail path) clears the session and leaves the user logged out. This replaces the current `Auth.auth().currentUser` + forced ID-token-refresh check. `logOut()` calls `authService.logout()`.

### `UserModel`

Adds a decoding path from the `Profile` JSON shape (`API.md`'s `dateOfBirth`/`createdAt` are ISO date strings, not Firestore `Timestamp`) — a new `init(profile: ProfileResponse)` alongside the existing `init(dictionary:)`. The existing `init(dictionary:)` stays untouched since it's not used by anything migrated in this pass.

### Error handling

`APIError` (from `APIClient`) is surfaced through `AuthViewModel`'s existing `errorMessage`/`errorTitle` pattern the same way `Error.localizedDescription` is today — no UI changes needed. The two documented error shapes (generic `{statusCode,message,error}` and the `{statusCode,code,message}` variant used by `/auth/refresh` and `/auth/logout`) are both decoded into the same `APIError` enum, distinguished by the presence of `code`, so `SessionStore`/`APIClient` can specifically detect `AUTH_REFRESH_TOKEN_INVALID` vs. a generic failure.

## Out of scope

- `WishlistService`, `GiftSuggestionService`, and their underlying Firestore/Supabase-Storage/Cloud-Functions usage — unchanged in this pass, covered by the broader `2026-07-25-nestjs-backend-migration-design.md` later.
- `FirebaseApp.configure()` and `GoogleService-Info.plist` — stay in place, since other parts of the app still depend on Firebase.
- Removing the `FirebaseAuth`, `Firebase`, `Supabase` SDK dependencies from the project — not done until everything that depends on them (wishlists, gift suggestions) also migrates.
- Production base URL — Railway deployment hasn't happened yet; `APIConfig` only needs to support Simulator/device local dev for now.
- Any change to `UserModel`'s Firestore-based `init(dictionary:)` path.

## Testing

- Unit tests for `SessionStore` (save/load/clear via Keychain, refresh single-flight behavior with concurrent callers).
- Unit tests for `APIClient`'s 401 → refresh → retry flow, and the "refresh also fails" → `sessionExpired` path.
- Unit tests for `AuthenticateService` methods against a mocked `APIClient`/`URLProtocol` stub, covering each endpoint's success and documented error responses.
- Manual verification: signup, login, Google sign-in (mobile `serverAuthCode` flow), reset-password, logout, and app-relaunch session restore, all against the locally running `wishie-server`.
