import Foundation
import UIKit
@testable import Wishie

final class MockProductMetadataService: ProductMetadataServiceProtocol {
    /// Map of URL -> result. Missing URL or `.failure` simulates a dead/invalid link.
    var results: [String: Result<ProductMetadata, Error>] = [:]

    func fetchMetadata(from urlString: String) async throws -> ProductMetadata {
        switch results[urlString] {
        case .success(let metadata): return metadata
        case .failure(let error): throw error
        case .none: throw URLError(.badURL)
        }
    }

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
}
