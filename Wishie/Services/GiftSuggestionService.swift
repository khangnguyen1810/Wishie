import Foundation

protocol GiftSuggestionServiceProtocol {
    func fetchIdeas(interests: [String], age: Int?, existingItemNames: [String], country: String?) async throws -> Result<GiftSuggestionResponse, WishieError>
}

final class GiftSuggestionService: GiftSuggestionServiceProtocol {
    
    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }
    
    func fetchIdeas(interests: [String], age: Int?, existingItemNames: [String], country: String?) async throws -> Result<GiftSuggestionResponse, WishieError> {
        do {
            let request = GiftSuggestionRequest(interests: interests, age: age, existingItems: existingItemNames, country: country)
            let response: GiftSuggestionResponse = try await apiService.send(.giftSuggestion(information: request))
            return .success(response)
        } catch {
            return .failure(WishieError(error))
        }
    }
}
