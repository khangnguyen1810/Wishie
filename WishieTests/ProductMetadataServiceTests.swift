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
