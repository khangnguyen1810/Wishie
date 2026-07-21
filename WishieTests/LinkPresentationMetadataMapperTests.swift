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
