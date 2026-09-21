// WishieTests/StubAPIService.swift
import Foundation
@testable import Wishie

final class StubAPIService: APIServiceProtocol {
    var sendResults: [Any] = []
    private(set) var sentRoutes: [APIRoute] = []

    func send<T>(_ route: APIRoute) async throws -> T where T: Decodable {
        sentRoutes.append(route)
        guard !sendResults.isEmpty else {
            fatalError("StubAPIService.sendResults exhausted — add a result before calling send()")
        }
        let next = sendResults.removeFirst()
        if let error = next as? Error {
            throw error
        }
        guard let value = next as? T else {
            fatalError("StubAPIService result type mismatch: expected \(T.self), got \(type(of: next))")
        }
        return value
    }
}
