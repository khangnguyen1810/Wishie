import Foundation
import FirebaseFunctions

protocol GiftSuggestionServiceProtocol {
    func fetchIdeas(interests: [String], age: Int?, existingItemNames: [String]) async throws -> [GiftIdea]
}

final class GiftSuggestionService: GiftSuggestionServiceProtocol {
    private lazy var functions = Functions.functions()

    func fetchIdeas(interests: [String], age: Int?, existingItemNames: [String]) async throws -> [GiftIdea] {
        var payload: [String: Any] = [
            "interests": interests,
            "existingItemNames": existingItemNames
        ]
        if let age { payload["age"] = age }

        let result = try await functions.httpsCallable("suggestGifts").call(payload)
        return GiftIdea.parse(from: result.data)
    }
}
