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
