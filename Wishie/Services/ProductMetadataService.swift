import Foundation
import WebKit

protocol ProductMetadataServiceProtocol {
    func fetchMetadata(from urlString: String) async throws -> ProductMetadata
}

class ProductMetadataService: ProductMetadataServiceProtocol {

    func fetchMetadata(from urlString: String) async throws -> ProductMetadata {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        guard url.scheme == "https" || url.scheme == "http" else {
            throw URLError(.badURL)
        }
        return try await WebViewMetadataExtractor().extract(from: url)
    }
}
