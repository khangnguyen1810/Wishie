import Testing
import Foundation
import UIKit
@testable import Wishie

@MainActor
struct GiftSuggestionViewModelTests {

    final class StubSuggestionService: GiftSuggestionServiceProtocol {
        var ideas: [GiftIdea] = []
        var error: Error?
        private(set) var didCallFetch = false
        private(set) var receivedAge: Int?
        private(set) var receivedCountry: String?
        func fetchIdeas(interests: [String], age: Int?, existingItemNames: [String], country: String?) async throws -> [GiftIdea] {
            didCallFetch = true
            receivedAge = age
            receivedCountry = country
            if let error { throw error }
            return ideas
        }
    }

    struct StubCountryProvider: CountryProviding {
        let name: String?
        func resolveCountryName() async -> String? { name }
    }

    func makeIdeas(_ count: Int) -> [GiftIdea] {
        (0..<count).map { i in
            GiftIdea(name: "Gift \(i)", description: "d", price: "$1", link: "https://ex.com/\(i)")
        }
    }

    func authStub(interests: [String]) -> MockAuthenticateService {
        let auth = MockAuthenticateService()
        auth.userToReturn = UserModel(dictionary: ["interests": interests])
        return auth
    }

    @Test func generateKeepsFirstSixValidatedAndDropsFailures() async {
        let suggestion = StubSuggestionService()
        suggestion.ideas = makeIdeas(10)

        let metadata = MockProductMetadataService()
        // Fail #2 and #5; all others validate.
        for i in 0..<10 where i != 2 && i != 5 {
            metadata.results["https://ex.com/\(i)"] = .success(MockProductMetadataService.metadata(for: "https://ex.com/\(i)"))
        }

        let vm = GiftSuggestionViewModel(
            existingItemNames: [],
            suggestionService: suggestion,
            metadataService: metadata,
            authService: authStub(interests: ["gaming"]),
            countryProvider: StubCountryProvider(name: nil)
        )
        await vm.generate()

        #expect(vm.suggestions.count == 6)
        #expect(vm.phase == .results)
        #expect(!vm.suggestions.contains { $0.metadata.productUrl == "https://ex.com/2" })
    }

    @Test func generateWithTooFewValidatedSetsEmptyPhase() async {
        let suggestion = StubSuggestionService()
        suggestion.ideas = makeIdeas(10)
        let metadata = MockProductMetadataService()
        // Only 2 validate (< minResults of 3).
        metadata.results["https://ex.com/0"] = .success(MockProductMetadataService.metadata(for: "https://ex.com/0"))
        metadata.results["https://ex.com/1"] = .success(MockProductMetadataService.metadata(for: "https://ex.com/1"))

        let vm = GiftSuggestionViewModel(
            existingItemNames: [],
            suggestionService: suggestion,
            metadataService: metadata,
            authService: authStub(interests: ["gaming"]),
            countryProvider: StubCountryProvider(name: nil)
        )
        await vm.generate()

        #expect(vm.suggestions.count == 2)
        #expect(vm.phase == .empty)
    }

    @Test func generateSurfacesServiceError() async {
        let suggestion = StubSuggestionService()
        suggestion.error = URLError(.notConnectedToInternet)
        let vm = GiftSuggestionViewModel(
            existingItemNames: [],
            suggestionService: suggestion,
            metadataService: MockProductMetadataService(),
            authService: authStub(interests: ["gaming"]),
            countryProvider: StubCountryProvider(name: nil)
        )
        await vm.generate()

        if case .error = vm.phase { } else { Issue.record("expected error phase, got \(vm.phase)") }
    }

    @Test func startWithNoInterestsRequestsInterests() async {
        let vm = GiftSuggestionViewModel(
            existingItemNames: [],
            suggestionService: StubSuggestionService(),
            metadataService: MockProductMetadataService(),
            authService: authStub(interests: [])
        )
        await vm.start()
        #expect(vm.phase == .needsInterests)
    }

    @Test func startSurfacesAuthErrorInsteadOfNeedsInterests() async {
        let auth = MockAuthenticateService()
        auth.getUserInfoError = URLError(.notConnectedToInternet)

        let vm = GiftSuggestionViewModel(
            existingItemNames: [],
            suggestionService: StubSuggestionService(),
            metadataService: MockProductMetadataService(),
            authService: auth
        )
        await vm.start()

        if case .error = vm.phase { } else { Issue.record("expected error phase, got \(vm.phase)") }
    }

    @Test func generateOmitsAgeForDefaultPlaceholderDateOfBirth() async {
        // authStub builds a UserModel whose dateOfBirth defaults to "now" (the
        // placeholder social sign-up writes), which would compute to age 0.
        let suggestion = StubSuggestionService()
        let vm = GiftSuggestionViewModel(
            existingItemNames: [],
            suggestionService: suggestion,
            metadataService: MockProductMetadataService(),
            authService: authStub(interests: ["gaming"]),
            countryProvider: StubCountryProvider(name: nil)
        )
        await vm.generate()

        #expect(suggestion.didCallFetch)
        #expect(suggestion.receivedAge == nil)
    }

    @Test func generatePassesResolvedCountryToService() async {
        let suggestion = StubSuggestionService()
        suggestion.ideas = makeIdeas(3)
        let metadata = MockProductMetadataService()
        for i in 0..<3 {
            metadata.results["https://ex.com/\(i)"] = .success(MockProductMetadataService.metadata(for: "https://ex.com/\(i)"))
        }

        let vm = GiftSuggestionViewModel(
            existingItemNames: [],
            suggestionService: suggestion,
            metadataService: metadata,
            authService: authStub(interests: ["gaming"]),
            countryProvider: StubCountryProvider(name: "Vietnam")
        )
        await vm.generate()

        #expect(suggestion.receivedCountry == "Vietnam")
    }

    /// LinkPresentation results carry a decoded image and no image URL. The
    /// validation filter must accept them, or the fast path yields nothing.
    @Test func generateKeepsSuggestionsWithOnlyALocalImage() async {
        let suggestion = StubSuggestionService()
        suggestion.ideas = makeIdeas(6)

        let metadata = MockProductMetadataService()
        for i in 0..<6 {
            metadata.results["https://ex.com/\(i)"] = .success(
                ProductMetadata(
                    title: "Title \(i)",
                    productDescription: "Desc",
                    imageUrl: nil,
                    productUrl: "https://ex.com/\(i)",
                    price: "$10",
                    localImage: UIImage(systemName: "gift")!
                )
            )
        }

        let vm = GiftSuggestionViewModel(
            existingItemNames: [],
            suggestionService: suggestion,
            metadataService: metadata,
            authService: authStub(interests: ["gaming"]),
            countryProvider: StubCountryProvider(name: nil)
        )
        await vm.generate()

        #expect(vm.suggestions.count == 6)
        #expect(vm.phase == .results)
    }
}
