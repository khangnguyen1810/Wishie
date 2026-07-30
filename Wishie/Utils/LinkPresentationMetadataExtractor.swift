import Foundation
import UIKit
import LinkPresentation
import os

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

    /// `LPMetadataProvider.timeout` bounds only the metadata fetch, and
    /// `NSItemProvider.loadObject` has no timeout of its own, so a stalled image
    /// transfer would otherwise hang the whole extraction.
    private static let imageLoadTimeout: TimeInterval = 5

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

        // The completion handler runs on an arbitrary queue and the deadline fires
        // on another, so the guard against a double resume has to be thread-safe.
        let hasResumed = OSAllocatedUnfairLock(initialState: false)

        return await withCheckedContinuation { continuation in
            func resumeOnce(with image: UIImage?) {
                let alreadyResumed = hasResumed.withLock { resumed -> Bool in
                    defer { resumed = true }
                    return resumed
                }
                guard !alreadyResumed else { return }
                continuation.resume(returning: image)
            }

            provider.loadObject(ofClass: UIImage.self) { object, _ in
                resumeOnce(with: object as? UIImage)
            }

            Task {
                try? await Task.sleep(nanoseconds: UInt64(imageLoadTimeout * 1_000_000_000))
                resumeOnce(with: nil)
            }
        }
    }
}
