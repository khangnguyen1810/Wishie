import Foundation
@testable import Wishie

final class InMemoryKeychain: KeychainStoring {
    private var storage: [String: String] = [:]

    func save(key: String, value: String) {
        storage[key] = value
    }

    func load(key: String) -> String? {
        storage[key]
    }

    func delete(key: String) {
        storage[key] = nil
    }
}
