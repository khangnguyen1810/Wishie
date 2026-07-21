# LinkPresentation Metadata Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `LPMetadataProvider` the primary source for product metadata, falling back to the existing hidden-`WKWebView` scraper only when LinkPresentation returns no title or no image.

**Architecture:** A shared `MetadataExtracting` protocol lets `ProductMetadataService` orchestrate two interchangeable extractors. A new `LinkPresentationMetadataExtractor` wraps `LPMetadataProvider`; a pure `LinkPresentationMetadataMapper` converts `LPLinkMetadata` to `ProductMetadata` so the conversion is testable without network. Because LinkPresentation yields a decoded `UIImage` rather than an image URL, `ProductMetadata` gains a `localImage` field mirroring the `image`/`localImage` pair `WishlistItem` already carries.

**Tech Stack:** Swift 5 language mode, SwiftUI, swift-testing (`import Testing`), LinkPresentation, WebKit, SDWebImageSwiftUI.

**Spec:** `docs/superpowers/specs/2026-07-21-linkpresentation-metadata-design.md`

## Global Constraints

- Language mode is `SWIFT_VERSION = 5.0`. Do not add Swift 6 strict-concurrency annotations beyond the `@MainActor` usage shown here.
- Deployment target is iOS 18.5.
- All tests use **swift-testing** (`import Testing`, `@Test`, `#expect`). Do **not** use XCTest. The only XCTest file in the repo is the throwaway spike deleted in Task 6.
- Extractors are **stateful per extraction**. `WebViewMetadataExtractor` stores `continuation`, `webView`, and `isTimedOut` on the instance, and `GiftSuggestionViewModel.validate(ideas:)` runs three `fetchMetadata` calls concurrently. A fresh extractor instance MUST be created for every extraction. Inject **factories**, never shared instances.
- `LPMetadataProvider` is single-use. Create a new one per request and never call `cancel()` after completion.
- `ProductMetadataService()` must keep working with no arguments — it is a default initializer value in `GiftSuggestionViewModel`, `CreateWishlistViewModel`, and `WishlistDetailViewController`.
- Test command used throughout (simulator UDID may differ on another machine; use any booted iPhone):

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie \
  -destination 'id=BBDB9BEC-7A77-4723-B680-5F84F3E0DDE5' \
  -parallel-testing-enabled NO \
  -only-testing:WishieTests/<SuiteName>
```

## File Structure

**Create:**
- `Wishie/Utils/MetadataExtracting.swift` — the shared extractor protocol.
- `Wishie/Utils/LinkPresentationMetadataMapper.swift` — pure `LPLinkMetadata` → `ProductMetadata` conversion.
- `Wishie/Utils/LinkPresentationMetadataExtractor.swift` — network + image loading around the mapper.
- `Wishie/CustomView/WishieProductImage.swift` — renders either a `UIImage` or a URL string.
- `WishieTests/LinkPresentationMetadataMapperTests.swift`
- `WishieTests/ProductMetadataServiceTests.swift`

**Modify:**
- `Wishie/Models/ProductMetadata.swift` — add `localImage`.
- `Wishie/Utils/WebViewMetadataExtractor.swift` — conform to `MetadataExtracting`.
- `Wishie/Services/ProductMetadataService.swift` — orchestration.
- `Wishie/Models/GiftSuggestion.swift` — carry `localImage` into `WishlistItem`.
- `Wishie/Screens/GiftSuggestions/GiftSuggestionViewModel.swift` — image filter.
- `Wishie/Screens/GiftSuggestions/GiftSuggestionCard.swift` — render local image.
- `Wishie/Screens/CreateList/CreateWishlistViewModel.swift` — carry `localImage`.
- `Wishie/Screens/CreateList/PasteLinkSheet.swift` — render local image.
- `Wishie/Screens/Detail/WishlistDetailViewController.swift` — carry `localImage`.
- `Wishie/Screens/Detail/AddItemPasteLinkDetailSheet.swift` — render local image.
- `WishieTests/GiftSuggestionViewModelTests.swift` — regression test.
- `WishieTests/MockProductMetadataService.swift` — helper gains `localImage`.

**Delete:**
- `WishieTests/LinkPresentationSpike.swift`

The project uses `PBXFileSystemSynchronizedRootGroup`, so new files under `Wishie/` and `WishieTests/` are picked up automatically. No `project.pbxproj` edits are needed.

---

### Task 1: `ProductMetadata.localImage`, the extractor protocol, and the mapper

**Files:**
- Modify: `Wishie/Models/ProductMetadata.swift`
- Create: `Wishie/Utils/MetadataExtracting.swift`
- Create: `Wishie/Utils/LinkPresentationMetadataMapper.swift`
- Test: `WishieTests/LinkPresentationMetadataMapperTests.swift`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `ProductMetadata.init(title:productDescription:imageUrl:productUrl:price:localImage:)` where `localImage: UIImage?` defaults to `nil`.
  - `protocol MetadataExtracting { @MainActor func extract(from url: URL) async throws -> ProductMetadata }`
  - `enum LinkPresentationMetadataMapper { static func map(_ metadata: LPLinkMetadata, requestedURL: URL, image: UIImage?) throws -> ProductMetadata }`
  - `enum LinkPresentationMetadataError: Error { case noUsableTitle }`

- [ ] **Step 1: Write the failing tests**

Create `WishieTests/LinkPresentationMetadataMapperTests.swift`:

```swift
import Testing
import Foundation
import UIKit
import LinkPresentation
@testable import Wishie

struct LinkPresentationMetadataMapperTests {

    private func makeLinkMetadata(title: String?, url: URL?) -> LPLinkMetadata {
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.url = url
        return metadata
    }

    private var requestedURL: URL { URL(string: "https://example.com/short")! }

    @Test func mapsTitleAndPrefersCanonicalURL() throws {
        let link = makeLinkMetadata(title: "  Samsung Monitor  ", url: URL(string: "https://example.com/dp/B0"))
        let result = try LinkPresentationMetadataMapper.map(link, requestedURL: requestedURL, image: nil)

        #expect(result.title == "Samsung Monitor")
        #expect(result.productUrl == "https://example.com/dp/B0")
    }

    @Test func fallsBackToRequestedURLWhenCanonicalMissing() throws {
        let link = makeLinkMetadata(title: "Keycap set", url: nil)
        let result = try LinkPresentationMetadataMapper.map(link, requestedURL: requestedURL, image: nil)

        #expect(result.productUrl == "https://example.com/short")
    }

    @Test func passesImageThroughAsLocalImage() throws {
        let image = UIImage(systemName: "gift")!
        let link = makeLinkMetadata(title: "Keycap set", url: nil)
        let result = try LinkPresentationMetadataMapper.map(link, requestedURL: requestedURL, image: image)

        #expect(result.localImage === image)
    }

    /// LinkPresentation never exposes these, so they must be empty rather than
    /// carrying a placeholder that later code could mistake for real data.
    @Test func leavesFieldsLinkPresentationCannotProvideEmpty() throws {
        let link = makeLinkMetadata(title: "Keycap set", url: nil)
        let result = try LinkPresentationMetadataMapper.map(link, requestedURL: requestedURL, image: nil)

        #expect(result.imageUrl == nil)
        #expect(result.price == nil)
        #expect(result.productDescription == "")
    }

    /// Absence is signalled by throwing, never by a placeholder title. A
    /// placeholder would read as non-empty and defeat the service's fallback.
    @Test func throwsWhenTitleIsMissing() {
        let link = makeLinkMetadata(title: nil, url: nil)
        #expect(throws: LinkPresentationMetadataError.noUsableTitle) {
            try LinkPresentationMetadataMapper.map(link, requestedURL: requestedURL, image: nil)
        }
    }

    @Test func throwsWhenTitleIsWhitespaceOnly() {
        let link = makeLinkMetadata(title: "   \n ", url: nil)
        #expect(throws: LinkPresentationMetadataError.noUsableTitle) {
            try LinkPresentationMetadataMapper.map(link, requestedURL: requestedURL, image: nil)
        }
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie \
  -destination 'id=BBDB9BEC-7A77-4723-B680-5F84F3E0DDE5' \
  -parallel-testing-enabled NO \
  -only-testing:WishieTests/LinkPresentationMetadataMapperTests
```

Expected: build failure — `cannot find 'LinkPresentationMetadataMapper' in scope`.

- [ ] **Step 3: Add `localImage` to the model**

Replace the whole of `Wishie/Models/ProductMetadata.swift`:

```swift
import Foundation
import UIKit

struct ProductMetadata: Hashable {
    let title: String
    let productDescription: String
    let imageUrl: String?
    let productUrl: String
    let price: String?
    /// Set when the metadata came from LinkPresentation, which hands back a
    /// decoded image rather than a URL. Mirrors `WishlistItem.localImage`.
    let localImage: UIImage?

    init(
        title: String,
        productDescription: String,
        imageUrl: String?,
        productUrl: String,
        price: String?,
        localImage: UIImage? = nil
    ) {
        self.title = title
        self.productDescription = productDescription
        self.imageUrl = imageUrl
        self.productUrl = productUrl
        self.price = price
        self.localImage = localImage
    }
}

extension ProductMetadata {
    /// True when this metadata carries an image in either representation.
    var hasImage: Bool {
        localImage != nil || imageUrl?.isEmpty == false
    }
}
```

An explicit initializer is required: a `let` property declared with `= nil` would be permanently `nil`, so the default has to live on the initializer parameter instead.

- [ ] **Step 4: Create the extractor protocol**

Create `Wishie/Utils/MetadataExtracting.swift`:

```swift
import Foundation

/// A single metadata extraction. Conformers hold per-extraction state, so
/// callers must create a fresh instance for every `extract(from:)` call.
@MainActor
protocol MetadataExtracting {
    func extract(from url: URL) async throws -> ProductMetadata
}
```

- [ ] **Step 5: Create the mapper**

Create `Wishie/Utils/LinkPresentationMetadataMapper.swift`:

```swift
import Foundation
import UIKit
import LinkPresentation

enum LinkPresentationMetadataError: Error {
    case noUsableTitle
}

/// Pure conversion from `LPLinkMetadata` to `ProductMetadata`, kept separate
/// from the network fetch so it can be tested in-process.
enum LinkPresentationMetadataMapper {

    static func map(
        _ metadata: LPLinkMetadata,
        requestedURL: URL,
        image: UIImage?
    ) throws -> ProductMetadata {
        let title = (metadata.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            throw LinkPresentationMetadataError.noUsableTitle
        }

        return ProductMetadata(
            title: title,
            // LPLinkMetadata has no description, price, or image URL.
            productDescription: "",
            imageUrl: nil,
            productUrl: metadata.url?.absoluteString ?? requestedURL.absoluteString,
            price: nil,
            localImage: image
        )
    }
}
```

- [ ] **Step 6: Run the tests to verify they pass**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie \
  -destination 'id=BBDB9BEC-7A77-4723-B680-5F84F3E0DDE5' \
  -parallel-testing-enabled NO \
  -only-testing:WishieTests/LinkPresentationMetadataMapperTests
```

Expected: `** TEST SUCCEEDED **`, six tests passing.

- [ ] **Step 7: Commit**

```bash
git add Wishie/Models/ProductMetadata.swift \
        Wishie/Utils/MetadataExtracting.swift \
        Wishie/Utils/LinkPresentationMetadataMapper.swift \
        WishieTests/LinkPresentationMetadataMapperTests.swift
git commit -m "feat: map LPLinkMetadata to ProductMetadata"
```

---

### Task 2: `LinkPresentationMetadataExtractor`

**Files:**
- Create: `Wishie/Utils/LinkPresentationMetadataExtractor.swift`
- Modify: `Wishie/Utils/WebViewMetadataExtractor.swift:5`

**Interfaces:**
- Consumes: `MetadataExtracting`, `LinkPresentationMetadataMapper.map(_:requestedURL:image:)` from Task 1.
- Produces: `final class LinkPresentationMetadataExtractor: MetadataExtracting` with a no-argument initializer.

This task has no unit test of its own: every path through it performs a real network fetch, and the repo's tests are hermetic. The conversion logic it depends on is already covered by Task 1, and its wiring is covered by Task 3's stubs. Verification here is a compile plus the existing suite.

- [ ] **Step 1: Create the extractor**

Create `Wishie/Utils/LinkPresentationMetadataExtractor.swift`:

```swift
import Foundation
import UIKit
import LinkPresentation

/// Fetches link metadata via `LPMetadataProvider`.
///
/// Faster than `WebViewMetadataExtractor` (measured 1.5–4.2s against 9–13.5s)
/// and returns a decoded image, but `LPLinkMetadata` carries no price or
/// description, so `ProductMetadataService` still falls back to the WebView
/// extractor when this yields too little.
@MainActor
final class LinkPresentationMetadataExtractor: MetadataExtracting {

    /// Measured worst case was 4.2s; 10s leaves headroom without making a
    /// failing link block the UI for the 30s default.
    private let timeout: TimeInterval = 10

    func extract(from url: URL) async throws -> ProductMetadata {
        // LPMetadataProvider is single-use, so this is created per extraction.
        let provider = LPMetadataProvider()
        provider.timeout = timeout

        let linkMetadata = try await provider.startFetchingMetadata(for: url)
        let image = await Self.loadImage(from: linkMetadata.imageProvider)

        return try LinkPresentationMetadataMapper.map(
            linkMetadata,
            requestedURL: url,
            image: image
        )
    }

    private static func loadImage(from provider: NSItemProvider?) async -> UIImage? {
        guard let provider, provider.canLoadObject(ofClass: UIImage.self) else { return nil }

        return await withCheckedContinuation { continuation in
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                continuation.resume(returning: object as? UIImage)
            }
        }
    }
}
```

- [ ] **Step 2: Conform the WebView extractor to the protocol**

In `Wishie/Utils/WebViewMetadataExtractor.swift`, change line 5 from:

```swift
final class WebViewMetadataExtractor: NSObject, WKNavigationDelegate {
```

to:

```swift
final class WebViewMetadataExtractor: NSObject, MetadataExtracting, WKNavigationDelegate {
```

Its existing `extract(from:)` already matches the protocol, so no other change is needed.

- [ ] **Step 3: Build and run the existing suite to confirm nothing regressed**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie \
  -destination 'id=BBDB9BEC-7A77-4723-B680-5F84F3E0DDE5' \
  -parallel-testing-enabled NO \
  -skip-testing:WishieTests/LinkPresentationSpike
```

Expected: `** TEST SUCCEEDED **`. The spike is skipped explicitly: it is still in the tree until Task 6 and hits the real network, so leaving it in would let an unrelated network failure look like a regression.

- [ ] **Step 4: Commit**

```bash
git add Wishie/Utils/LinkPresentationMetadataExtractor.swift \
        Wishie/Utils/WebViewMetadataExtractor.swift
git commit -m "feat: add LinkPresentation metadata extractor"
```

---

### Task 3: `ProductMetadataService` orchestration

**Files:**
- Modify: `Wishie/Services/ProductMetadataService.swift`
- Test: `WishieTests/ProductMetadataServiceTests.swift`

**Interfaces:**
- Consumes: `MetadataExtracting`, `ProductMetadata.hasImage` from Task 1; both extractors from Task 2.
- Produces: `ProductMetadataService.init(makeLinkPresentationExtractor:makeWebViewExtractor:)` taking two `@MainActor @escaping () -> MetadataExtracting` factories, both defaulted.

The initializer takes **factories rather than instances** because extractors hold per-extraction state and `GiftSuggestionViewModel` fetches three links concurrently; sharing one instance would let concurrent extractions overwrite each other's continuation.

- [ ] **Step 1: Write the failing tests**

Create `WishieTests/ProductMetadataServiceTests.swift`:

```swift
import Testing
import Foundation
import UIKit
@testable import Wishie

@MainActor
struct ProductMetadataServiceTests {

    /// Records how many times it was asked to extract, so tests can assert the
    /// WebView extractor is skipped entirely on the fast path.
    final class StubExtractor: MetadataExtracting {
        var result: Result<ProductMetadata, Error>
        private(set) var callCount = 0

        init(result: Result<ProductMetadata, Error>) {
            self.result = result
        }

        func extract(from url: URL) async throws -> ProductMetadata {
            callCount += 1
            return try result.get()
        }
    }

    private func metadata(
        title: String = "Product",
        imageUrl: String? = nil,
        localImage: UIImage? = nil,
        price: String? = nil
    ) -> ProductMetadata {
        ProductMetadata(
            title: title,
            productDescription: "",
            imageUrl: imageUrl,
            productUrl: "https://example.com/p",
            price: price,
            localImage: localImage
        )
    }

    private func makeService(
        linkPresentation: StubExtractor,
        webView: StubExtractor
    ) -> ProductMetadataService {
        ProductMetadataService(
            makeLinkPresentationExtractor: { linkPresentation },
            makeWebViewExtractor: { webView }
        )
    }

    private var anImage: UIImage { UIImage(systemName: "gift")! }

    @Test func returnsLinkPresentationResultWithoutTouchingWebView() async throws {
        let lp = StubExtractor(result: .success(metadata(title: "Fast", localImage: anImage)))
        let web = StubExtractor(result: .success(metadata(title: "Slow")))
        let service = makeService(linkPresentation: lp, webView: web)

        let result = try await service.fetchMetadata(from: "https://example.com/p")

        #expect(result.title == "Fast")
        #expect(web.callCount == 0)
    }

    @Test func fallsBackToWebViewWhenLinkPresentationHasNoImage() async throws {
        let lp = StubExtractor(result: .success(metadata(title: "No image")))
        let web = StubExtractor(result: .success(metadata(title: "Scraped", imageUrl: "https://img/1.jpg")))
        let service = makeService(linkPresentation: lp, webView: web)

        let result = try await service.fetchMetadata(from: "https://example.com/p")

        #expect(result.title == "Scraped")
        #expect(web.callCount == 1)
    }

    @Test func fallsBackToWebViewWhenLinkPresentationThrows() async throws {
        let lp = StubExtractor(result: .failure(LinkPresentationMetadataError.noUsableTitle))
        let web = StubExtractor(result: .success(metadata(title: "Scraped", imageUrl: "https://img/1.jpg")))
        let service = makeService(linkPresentation: lp, webView: web)

        let result = try await service.fetchMetadata(from: "https://example.com/p")

        #expect(result.title == "Scraped")
    }

    /// The WebView extractor got a title but no image; LinkPresentation had an
    /// image. Keep both rather than discarding the image we already paid for.
    @Test func webViewResultInheritsLinkPresentationImage() async throws {
        let image = anImage
        let lp = StubExtractor(result: .success(metadata(title: "No image", localImage: image)))
        let web = StubExtractor(result: .success(metadata(title: "Scraped", price: "100")))
        let service = makeService(linkPresentation: lp, webView: web)

        let result = try await service.fetchMetadata(from: "https://example.com/p")

        #expect(result.title == "Scraped")
        #expect(result.price == "100")
        #expect(result.localImage === image)
    }

    @Test func returnsLinkPresentationResultWhenWebViewFails() async throws {
        let lp = StubExtractor(result: .success(metadata(title: "Title only")))
        let web = StubExtractor(result: .failure(URLError(.timedOut)))
        let service = makeService(linkPresentation: lp, webView: web)

        let result = try await service.fetchMetadata(from: "https://example.com/p")

        #expect(result.title == "Title only")
    }

    @Test func throwsWhenBothExtractorsFail() async {
        let lp = StubExtractor(result: .failure(LinkPresentationMetadataError.noUsableTitle))
        let web = StubExtractor(result: .failure(URLError(.timedOut)))
        let service = makeService(linkPresentation: lp, webView: web)

        await #expect(throws: URLError.self) {
            try await service.fetchMetadata(from: "https://example.com/p")
        }
    }

    @Test func rejectsNonHTTPSchemesBeforeExtracting() async {
        let lp = StubExtractor(result: .success(metadata()))
        let web = StubExtractor(result: .success(metadata()))
        let service = makeService(linkPresentation: lp, webView: web)

        await #expect(throws: URLError.self) {
            try await service.fetchMetadata(from: "ftp://example.com/p")
        }
        #expect(lp.callCount == 0)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie \
  -destination 'id=BBDB9BEC-7A77-4723-B680-5F84F3E0DDE5' \
  -parallel-testing-enabled NO \
  -only-testing:WishieTests/ProductMetadataServiceTests
```

Expected: build failure — `extra arguments at positions #1, #2 in call` for `ProductMetadataService(makeLinkPresentationExtractor:makeWebViewExtractor:)`.

- [ ] **Step 3: Implement the orchestration**

Replace the whole of `Wishie/Services/ProductMetadataService.swift`:

```swift
import Foundation

protocol ProductMetadataServiceProtocol {
    func fetchMetadata(from urlString: String) async throws -> ProductMetadata
}

class ProductMetadataService: ProductMetadataServiceProtocol {

    private let makeLinkPresentationExtractor: @MainActor () -> MetadataExtracting
    private let makeWebViewExtractor: @MainActor () -> MetadataExtracting

    /// Extractors are built per extraction rather than injected as instances:
    /// both hold state for the duration of one extraction, and callers such as
    /// `GiftSuggestionViewModel` fetch several links concurrently.
    init(
        makeLinkPresentationExtractor: @escaping @MainActor () -> MetadataExtracting = { LinkPresentationMetadataExtractor() },
        makeWebViewExtractor: @escaping @MainActor () -> MetadataExtracting = { WebViewMetadataExtractor() }
    ) {
        self.makeLinkPresentationExtractor = makeLinkPresentationExtractor
        self.makeWebViewExtractor = makeWebViewExtractor
    }

    func fetchMetadata(from urlString: String) async throws -> ProductMetadata {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        guard url.scheme == "https" || url.scheme == "http" else {
            throw URLError(.badURL)
        }
        return try await resolve(url: url)
    }

    @MainActor
    private func resolve(url: URL) async throws -> ProductMetadata {
        let linkPresentationResult = try? await makeLinkPresentationExtractor().extract(from: url)

        // LinkPresentation is enough only when it produced both a title and an
        // image; it never produces a price, and the gift suggestion flow
        // requires an image.
        if let linkPresentationResult, linkPresentationResult.hasImage {
            return linkPresentationResult
        }

        do {
            let webViewResult = try await makeWebViewExtractor().extract(from: url)
            return merge(webViewResult: webViewResult, linkPresentationResult: linkPresentationResult)
        } catch {
            // The WebView extractor is the more capable of the two, so its
            // failure is the more informative error to surface.
            guard let linkPresentationResult else { throw error }
            return linkPresentationResult
        }
    }

    /// Carries the LinkPresentation image over when the WebView scrape found none.
    private func merge(
        webViewResult: ProductMetadata,
        linkPresentationResult: ProductMetadata?
    ) -> ProductMetadata {
        guard !webViewResult.hasImage, let localImage = linkPresentationResult?.localImage else {
            return webViewResult
        }

        return ProductMetadata(
            title: webViewResult.title,
            productDescription: webViewResult.productDescription,
            imageUrl: webViewResult.imageUrl,
            productUrl: webViewResult.productUrl,
            price: webViewResult.price,
            localImage: localImage
        )
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie \
  -destination 'id=BBDB9BEC-7A77-4723-B680-5F84F3E0DDE5' \
  -parallel-testing-enabled NO \
  -only-testing:WishieTests/ProductMetadataServiceTests
```

Expected: `** TEST SUCCEEDED **`, seven tests passing.

- [ ] **Step 5: Commit**

```bash
git add Wishie/Services/ProductMetadataService.swift \
        WishieTests/ProductMetadataServiceTests.swift
git commit -m "feat: try LinkPresentation before the WebView scraper"
```

---

### Task 4: Keep LinkPresentation results in the gift suggestion flow

**Files:**
- Modify: `Wishie/Screens/GiftSuggestions/GiftSuggestionViewModel.swift:117-119`
- Modify: `Wishie/Models/GiftSuggestion.swift:39-47`
- Test: `WishieTests/GiftSuggestionViewModelTests.swift`
- Modify: `WishieTests/MockProductMetadataService.swift`

**Interfaces:**
- Consumes: `ProductMetadata.hasImage` and `ProductMetadata.localImage` from Task 1.
- Produces: `MockProductMetadataService.metadata(for:localImage:)` gaining a defaulted `localImage` parameter.

`GiftSuggestionViewModel` currently filters candidates on `metadata.imageUrl?.isEmpty == false`. LinkPresentation results always have a `nil` `imageUrl`, so without this change every fast-path result is silently discarded and the suggestions list collapses. This is the single easiest regression to miss in the whole change, so it gets its own test.

- [ ] **Step 1: Write the failing test**

Add to the `GiftSuggestionViewModelTests` struct in `WishieTests/GiftSuggestionViewModelTests.swift`:

```swift
    /// LinkPresentation results carry a decoded image and no image URL. The
    /// validation filter must accept them, or the fast path yields nothing.
    @Test func generateKeepsSuggestionsWithOnlyALocalImage() async {
        let suggestion = StubSuggestionService()
        suggestion.ideas = makeIdeas(6)

        let metadata = MockProductMetadataService()
        for i in 0..<6 {
            metadata.results["https://ex.com/\(i)"] = .success(
                ProductMetadata(
                    title: "Title \(i)",
                    productDescription: "Desc",
                    imageUrl: nil,
                    productUrl: "https://ex.com/\(i)",
                    price: "$10",
                    localImage: UIImage(systemName: "gift")!
                )
            )
        }

        let vm = GiftSuggestionViewModel(
            existingItemNames: [],
            suggestionService: suggestion,
            metadataService: metadata,
            authService: authStub(interests: ["gaming"]),
            countryProvider: StubCountryProvider(name: nil)
        )
        await vm.generate()

        #expect(vm.suggestions.count == 6)
        #expect(vm.phase == .results)
    }
```

Add `import UIKit` to the top of that file if it is not already present.

- [ ] **Step 2: Run the test to verify it fails**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie \
  -destination 'id=BBDB9BEC-7A77-4723-B680-5F84F3E0DDE5' \
  -parallel-testing-enabled NO \
  -only-testing:WishieTests/GiftSuggestionViewModelTests
```

Expected: FAIL — `Expectation failed: (vm.suggestions.count → 0) == 6`, because every candidate is filtered out.

- [ ] **Step 3: Accept either image representation in the filter**

In `Wishie/Screens/GiftSuggestions/GiftSuggestionViewModel.swift`, replace lines 117-119:

```swift
                        guard let metadata = try? await metadataService.fetchMetadata(from: idea.link),
                              metadata.imageUrl?.isEmpty == false
                        else { return nil }
```

with:

```swift
                        guard let metadata = try? await metadataService.fetchMetadata(from: idea.link),
                              metadata.hasImage
                        else { return nil }
```

- [ ] **Step 4: Carry the local image into the created item**

In `Wishie/Models/GiftSuggestion.swift`, replace the `toWishlistItem()` body:

```swift
    func toWishlistItem() -> WishlistItem {
        WishlistItem(
            name: metadata.title.isEmpty ? idea.name : metadata.title,
            description: metadata.productDescription.isEmpty ? idea.description : metadata.productDescription,
            image: metadata.imageUrl,
            localImage: metadata.localImage,
            itemLink: metadata.productUrl,
            price: (metadata.price?.isEmpty == false ? metadata.price : idea.price)
        )
    }
```

- [ ] **Step 5: Let the mock build metadata with a local image**

In `WishieTests/MockProductMetadataService.swift`, add `import UIKit` and replace the `metadata(for:)` helper:

```swift
    static func metadata(for url: String, localImage: UIImage? = nil) -> ProductMetadata {
        ProductMetadata(
            title: "Title \(url)",
            productDescription: "Desc",
            imageUrl: "https://img/\(url).jpg",
            productUrl: url,
            price: "$10",
            localImage: localImage
        )
    }
```

- [ ] **Step 6: Run the tests to verify they pass**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie \
  -destination 'id=BBDB9BEC-7A77-4723-B680-5F84F3E0DDE5' \
  -parallel-testing-enabled NO \
  -only-testing:WishieTests/GiftSuggestionViewModelTests
```

Expected: `** TEST SUCCEEDED **`, including the three pre-existing tests.

- [ ] **Step 7: Commit**

```bash
git add Wishie/Screens/GiftSuggestions/GiftSuggestionViewModel.swift \
        Wishie/Models/GiftSuggestion.swift \
        WishieTests/GiftSuggestionViewModelTests.swift \
        WishieTests/MockProductMetadataService.swift
git commit -m "fix: keep suggestions whose image came from LinkPresentation"
```

---

### Task 5: Carry the local image through the add-item flows

**Files:**
- Modify: `Wishie/Screens/CreateList/CreateWishlistViewModel.swift:69-78`
- Modify: `Wishie/Screens/Detail/WishlistDetailViewController.swift:317-323`

**Interfaces:**
- Consumes: `ProductMetadata.localImage` from Task 1.
- Produces: no new API. Both flows populate the `UIImage` slot their save paths already upload.

Both screens already have an upload path for a local image — `CreateWishlistViewModel` uploads `items[index].localImage` at lines 35-40, and `WishlistDetailViewController.addNewWishlistItem` uploads `newItemImage` at lines 252-257. These two edits simply connect the metadata to those existing paths.

- [ ] **Step 1: Populate `localImage` when adding from metadata**

In `Wishie/Screens/CreateList/CreateWishlistViewModel.swift`, replace `addItemFromMetadata`:

```swift
    func addItemFromMetadata(_ metadata: ProductMetadata) {
        let item = WishlistItem(
            name: metadata.title,
            description: metadata.productDescription,
            image: metadata.imageUrl,
            localImage: metadata.localImage,
            itemLink: metadata.productUrl,
            price: metadata.price
        )
        items.append(item)
    }
```

- [ ] **Step 2: Populate `newItemImage` when prefilling the detail sheet**

In `Wishie/Screens/Detail/WishlistDetailViewController.swift`, replace `setNewItemFromMetadata`:

```swift
    func setNewItemFromMetadata(_ metadata: ProductMetadata) {
        newItemName = metadata.title
        newItemDescription = metadata.productDescription
        newItemLink = metadata.productUrl
        newItemRemoteImageUrl = metadata.imageUrl
        newItemImage = metadata.localImage
        newItemPrice = metadata.price ?? ""
    }
```

- [ ] **Step 3: Clear the local image when a fetch fails**

Still in `Wishie/Screens/Detail/WishlistDetailViewController.swift`, the `catch` branch of `fetchProductMetadataForNewItem` resets the other prefilled fields but would leave a stale image behind. Replace that `catch` block:

```swift
        } catch {
            metadataFetchError = error.localizedDescription
            newItemName = ""
            newItemDescription = ""
            newItemRemoteImageUrl = nil
            newItemImage = nil
            newItemPrice = ""
        }
```

- [ ] **Step 4: Run the full suite**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie \
  -destination 'id=BBDB9BEC-7A77-4723-B680-5F84F3E0DDE5' \
  -parallel-testing-enabled NO \
  -skip-testing:WishieTests/LinkPresentationSpike
```

Expected: `** TEST SUCCEEDED **`. The spike is skipped for the same reason as in Task 2.

- [ ] **Step 5: Commit**

```bash
git add Wishie/Screens/CreateList/CreateWishlistViewModel.swift \
        Wishie/Screens/Detail/WishlistDetailViewController.swift
git commit -m "feat: carry LinkPresentation image into the add-item flows"
```

---

### Task 6: Render the local image, and remove the spike

**Files:**
- Create: `Wishie/CustomView/WishieProductImage.swift`
- Modify: `Wishie/Screens/CreateList/PasteLinkSheet.swift:62-66`
- Modify: `Wishie/Screens/Detail/AddItemPasteLinkDetailSheet.swift:76-80`
- Modify: `Wishie/Screens/GiftSuggestions/GiftSuggestionCard.swift:9-13`
- Delete: `WishieTests/LinkPresentationSpike.swift`

**Interfaces:**
- Consumes: `ProductMetadata.localImage` from Task 1.
- Produces: `WishieProductImage(localImage:url:contentMode:placeholderSize:)`, a view rendering whichever image representation is available.

The three preview surfaces currently render through `WishieWebImage(url:)`, which only accepts a URL string. Without this task, LinkPresentation results show no image anywhere in the UI. The shared decision lives in one view rather than being repeated three times.

- [ ] **Step 1: Create the shared image view**

Create `Wishie/CustomView/WishieProductImage.swift`:

```swift
import SwiftUI

/// Renders product artwork from either representation: LinkPresentation hands
/// back a decoded `UIImage`, the WebView scraper an image URL.
struct WishieProductImage: View {
    let localImage: UIImage?
    let url: String?
    let contentMode: ContentMode
    let placeholderSize: CGFloat

    init(
        localImage: UIImage?,
        url: String?,
        contentMode: ContentMode = .fill,
        placeholderSize: CGFloat = 100
    ) {
        self.localImage = localImage
        self.url = url
        self.contentMode = contentMode
        self.placeholderSize = placeholderSize
    }

    var body: some View {
        if let localImage {
            Image(uiImage: localImage)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else if let url, !url.isEmpty {
            WishieWebImage(
                url: url,
                contentMode: contentMode,
                placeholderSize: placeholderSize
            )
        }
    }
}
```

- [ ] **Step 2: Use it in the create-list paste sheet**

In `Wishie/Screens/CreateList/PasteLinkSheet.swift`, replace lines 62-66:

```swift
                    if let imageUrl = metadata.imageUrl {
                        WishieWebImage(url: imageUrl)
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
```

with:

```swift
                    if metadata.hasImage {
                        WishieProductImage(localImage: metadata.localImage, url: metadata.imageUrl)
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
```

- [ ] **Step 3: Use it in the detail paste sheet**

In `Wishie/Screens/Detail/AddItemPasteLinkDetailSheet.swift`, replace lines 76-80:

```swift
                    if let imageUrl = viewModel.newItemRemoteImageUrl {
                        WishieWebImage(url: imageUrl)
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
```

with:

```swift
                    if viewModel.newItemImage != nil || viewModel.newItemRemoteImageUrl?.isEmpty == false {
                        WishieProductImage(
                            localImage: viewModel.newItemImage,
                            url: viewModel.newItemRemoteImageUrl
                        )
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
```

- [ ] **Step 4: Use it in the gift suggestion card**

In `Wishie/Screens/GiftSuggestions/GiftSuggestionCard.swift`, replace lines 9-13:

```swift
            if let imageUrl = suggestion.metadata.imageUrl {
                WishieWebImage(url: imageUrl)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
```

with:

```swift
            if suggestion.metadata.hasImage {
                WishieProductImage(
                    localImage: suggestion.metadata.localImage,
                    url: suggestion.metadata.imageUrl
                )
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
```

- [ ] **Step 5: Delete the spike**

The spike hits the real network and is the only XCTest file in the repo. Its purpose — choosing between the two extractors — is served.

```bash
git rm WishieTests/LinkPresentationSpike.swift
```

- [ ] **Step 6: Run the full suite**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie \
  -destination 'id=BBDB9BEC-7A77-4723-B680-5F84F3E0DDE5' \
  -parallel-testing-enabled NO
```

Expected: `** TEST SUCCEEDED **`, with no network-dependent tests remaining.

- [ ] **Step 7: Verify in the running app**

Automated tests cannot confirm that artwork actually appears. Launch the app, paste the Lazada link `https://s.lazada.vn/s.nsdtD?c=v` into the add-item sheet, and confirm the title and image populate in roughly two seconds rather than the previous thirteen.

- [ ] **Step 8: Commit**

```bash
git add Wishie/CustomView/WishieProductImage.swift \
        Wishie/Screens/CreateList/PasteLinkSheet.swift \
        Wishie/Screens/Detail/AddItemPasteLinkDetailSheet.swift \
        Wishie/Screens/GiftSuggestions/GiftSuggestionCard.swift
git commit -m "feat: render product images from LinkPresentation"
```

---

## Out of scope

Neither extractor retrieves a title for Shopee, and price extraction returns nothing on any of the three measured sites. Both are real problems, both are recorded in the spec, and neither is addressed here. Do not widen this plan to chase them.
