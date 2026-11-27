# Swift 6 strict concurrency — migration backlog

**Status:** backlog (not started) · **Measured:** 2026-11-27 on `develop` @ `fc08b4c`

## Goal

Move the `Wishie` and `WishieTests` targets from `SWIFT_VERSION = 5.0` to Swift 6 language mode, so data races are caught at compile time. That makes it safe to move more work off the main thread, and that's where the concurrency performance gains come from. Swift 6 mode alone does not make the app faster. Profile with Instruments before optimizing.

## How this was measured

Set `SWIFT_STRICT_CONCURRENCY = complete` on the Wishie targets only (not via the command line, because that also applies to SPM packages and FirebaseAuth fails to compile), then:

```bash
xcodebuild build-for-testing -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Result: build succeeds, **120 concurrency warnings** in our code (99 app, 21 tests). Each one becomes an **error** in Swift 6 mode. Re-run this to track progress.

## Plan

Work on a `refactor/…` style series of PRs (one step per PR, tests green after each). Use the `ios-senior-dev` agent (`.claude/agents/ios-senior-dev.md`).

1. **Enable `SWIFT_STRICT_CONCURRENCY = complete`** on `Wishie` + `WishieTests` (still Swift 5 mode) so warnings stay visible in Xcode.
2. **Services & protocols** (unblocks ~45 warnings): make `WishlistServiceProtocol`, `AuthenticateServiceProtocol`, `ProductMetadataServiceProtocol`, the gift-suggestion service and the country provider `Sendable` (or `@MainActor` if they touch UI state). Fix `WishlistService`, `AuthenticateService`.
3. **Auth flow**: `AuthViewModel` (31 warnings). Replace callback/`@Sendable` closures capturing `self` with `async` wrappers (`withCheckedThrowingContinuation`) around Google Sign-In / Firebase Auth.
4. **Networking**: `APIClient` (`[weak self]` in `@Sendable` closure), `WishieRequestInterceptor` (Alamofire `adapt`/`retry` completions).
5. **Detail & QR UIKit screens**: `WishlistDetailViewController` (`@preconcurrency import FirebaseFirestore`, listener cleanup in `deinit`), `QRScannerViewController` (`AVCaptureSession` start/stop on a dedicated serial executor/actor, delegate conformance via `nonisolated` + hop to main).
6. **Globals & singletons**: `KeychainManager`, `LocationManager`, `SupabaseManager` `shared`; `PreferenceKey.defaultValue` → `static let`; `AuthScaffold` environment default.
7. **Small leftovers**: `LinkHelper`, `ImagePickerBox`, `TopPickCard` `Equatable`, `LinkPresentationMetadataExtractor`, `CreateWishListScreen`.
8. **Tests**: `MockURLProtocol.requestHandler` (protect with a lock / `Mutex`), captured `var`s in `APIClientTests` / `APIServiceTests` (use a lock-protected box), `@MainActor` on suites that create `AuthViewModel`, `ProductMetadataServiceTests`.
9. **Flip `SWIFT_VERSION = 6`** on both targets, build, run the full `WishieTests` suite.

Unrelated warnings found in the same build (fix separately): asset catalog — image set `forest` references missing files `Thiết kế chưa có tên (5)@2x/@3x.png`; `forest` and `purpleDream` have 3 unassigned children.

## Warnings by category

| Count | Kind | Typical fix |
|---|---|---|
| 57 | Sending `self` / non-Sendable value (services) across isolation | `Sendable` service protocols, `@MainActor` VMs, async APIs |
| 37 | Captured `self`/`var` in `@Sendable` / `sending` closure | async/await instead of callbacks; lock-protected box in tests |
| 9 | Global/static mutable state | `static let`, `@MainActor`, actor, `Mutex` |
| 3 | Protocol conformance crossing into main actor | `nonisolated` requirement + hop to `MainActor` |
| 14 | Other (deinit access, main-actor init in tests, `@preconcurrency` imports, local func `@Sendable`) | case by case |

## Full list (file:line — diagnostic)

### App — `Wishie/`

**Auth**
- Screens/Auth/AuthViewModel.swift:57, 107, 129, 151, 178, 206 — passing closure as a `sending` parameter
- Screens/Auth/AuthViewModel.swift:65, 91, 111, 118, 133, 140, 155, 162, 181, 209 — capture of `self` (non-Sendable `AuthViewModel`) in `@Sendable` closure + sending `self`
- Screens/Auth/AuthViewModel.swift:115, 137, 159, 198 — sending `self`
- Screens/Auth/AuthViewModel.swift:194 — sending `self.authService`
- Screens/Auth/AuthScaffold.swift:9 — static `defaultValue` of type `(String) -> Void` not concurrency-safe

**Detail**
- Screens/Detail/WishlistDetailViewController.swift:10 — add `@preconcurrency` for `FirebaseFirestoreInternal`
- Screens/Detail/WishlistDetailViewController.swift:56 — `wishlistListener` (non-Sendable `ListenerRegistration`) accessed from nonisolated `deinit`
- Screens/Detail/WishlistDetailViewController.swift:62, 84, 131, 179, 211, 239, 250, 277, 280 — sending non-Sendable `any WishlistServiceProtocol`
- Screens/Detail/WishlistDetailViewController.swift:112 — sending non-Sendable `any AuthenticateServiceProtocol`
- Screens/Detail/WishlistDetailViewController.swift:295 — sending non-Sendable `any ProductMetadataServiceProtocol`
- Screens/Detail/TopPickCard.swift:20, 143 — `Equatable` conformance of `TopPickCard` / `TopPickThumbnail` crosses into main actor
- Screens/Detail/StickyHeaderView.swift:163, Screens/Detail/WishlistDetailView.swift:13 — static `defaultValue` is mutable global state

**Home / Archived / Lists**
- Screens/Home/HomeViewModel.swift:33, 47, 61, 75 — sending non-Sendable `any WishlistServiceProtocol`
- Screens/Home/HomeViewModel.swift:36, 37 — non-Sendable `service` cannot exit main actor
- Screens/Archived/ArchivedWishlistsViewModel.swift:27, 29, 37, 51 — sending non-Sendable `any WishlistServiceProtocol`
- Screens/Information/WishListInformationViewModel.swift:33 — same
- Screens/EditWishlistInfo/EditWishlistInfoViewModel.swift:42, 65 — same
- Screens/CreateList/CreateWishlistViewModel.swift:49 — sending non-Sendable `any ProductMetadataServiceProtocol`
- Screens/CreateList/CreateWishListScreen.swift:73 — sending `self.createWishlistViewModel`

**Gift suggestions / Profile / Interests**
- Screens/GiftSuggestions/GiftSuggestionViewModel.swift:42, 60, 71 — sending `self.authService`
- Screens/GiftSuggestions/GiftSuggestionViewModel.swift:80 — sending `self.countryProvider`
- Screens/GiftSuggestions/GiftSuggestionViewModel.swift:84 — sending `self.suggestionService`
- Screens/GiftSuggestions/GiftSuggestionViewModel.swift:121 — passing closure as `sending` from main actor
- Screens/Profile/EditProfileViewModel.swift:52, 56; Screens/Profile/ProfileViewModel.swift:19; Screens/Interests/InterestsViewModel.swift:42 — sending `self.authService`

**QR**
- Screens/Qr/QRScannerViewController.swift:9 — add `@preconcurrency` for `AVFoundation`
- Screens/Qr/QRScannerViewController.swift:62, 79, 99 — capture of non-Sendable `AVCaptureSession` in `@Sendable` closure
- Screens/Qr/QRScannerViewController.swift:85 — `AVCaptureMetadataOutputObjectsDelegate` conformance crosses into main actor
- Screens/Qr/ScanQRScreenViewModel.swift:102; Screens/Qr/WishlistQRCodeViewModel.swift:30 — sending `self.wishlistService`

**Services / Networking**
- Services/WishlistService.swift:56 — capture of non-Sendable `Self.Type` + passing closure as `sending`
- Services/WishlistService.swift:96 — passing closure as `sending`
- Services/AuthenticateService.swift:146 — sending `result`
- Networking/APIClient.swift:47 — capture of `self` (`APIClient?`) in `@Sendable` closure
- Networking/WishieRequestInterceptor.swift:20, 44 — passing closure as `sending`

**Managers / Helpers / Utils / CustomView**
- Manager/KeychainManager.swift:13, Manager/LocationManager.swift:14, Manager/SupabaseManager.swift:11 — static `shared` of non-Sendable type
- Helper/CoachMarkBoundsKey.swift:6, Helper/TextHeightKey.swift:12 — static `defaultValue` is mutable global state
- LinkHelper.swift:13 — `UIApplication.shared.open` called from nonisolated context
- Utils/LinkPresentationMetadataExtractor.swift:47, 57 — local func `resumeOnce(with:)` must be `@Sendable`
- CustomView/ImagePickerBox.swift:23 — main-actor `content` referenced from `@Sendable` closure; capture of non-Sendable `Content.Type`

### Tests — `WishieTests/`

- MockURLProtocol.swift:4 — static `requestHandler` is mutable global state
- APIClientTests.swift:34, 68, 124, 147, 177 — mutation of captured var in concurrently-executing code
- APIServiceTests.swift:40, 55, 88, 143, 170, 171 — same
- AuthViewModelGoogleLoginTests.swift:20, 34, 45 — main-actor `init()` called from nonisolated context (mark suite `@MainActor`)
- ProductMetadataServiceTests.swift:58, 69, 80, 90, 113, 114 — sending `service`
