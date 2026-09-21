import Foundation
@testable import Wishie

final class StubAPIClient: APIClientProtocol {
    var sendResults: [Any] = []
    var sendNoContentError: Error?
    private(set) var sentEndpoints: [Endpoint] = []

    func send<T>(_ endpoint: Endpoint) async throws -> T where T: Decodable {
        sentEndpoints.append(endpoint)
        guard !sendResults.isEmpty else {
            fatalError("StubAPIClient.sendResults exhausted — add a result before calling send()")
        }
        let next = sendResults.removeFirst()
        if let error = next as? Error {
            throw error
        }
        guard let value = next as? T else {
            fatalError("StubAPIClient result type mismatch: expected \(T.self), got \(type(of: next))")
        }
        return value
    }

    func sendNoContent(_ endpoint: Endpoint) async throws {
        sentEndpoints.append(endpoint)
        if let sendNoContentError {
            throw sendNoContentError
        }
    }
}
