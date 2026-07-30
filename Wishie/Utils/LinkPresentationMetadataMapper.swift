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
