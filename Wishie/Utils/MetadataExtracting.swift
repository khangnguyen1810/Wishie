import Foundation

/// A single metadata extraction. Conformers hold per-extraction state, so
/// callers must create a fresh instance for every `extract(from:)` call.
@MainActor
protocol MetadataExtracting {
    func extract(from url: URL) async throws -> ProductMetadata
}
