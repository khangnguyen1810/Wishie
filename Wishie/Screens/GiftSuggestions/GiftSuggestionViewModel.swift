import Foundation

enum GiftSuggestionPhase: Equatable {
    case idle
    case needsInterests
    case loading
    case results
    case empty
    case error(String)
}

@MainActor
final class GiftSuggestionViewModel: ObservableObject {
    @Published var phase: GiftSuggestionPhase = .idle
    @Published var suggestions: [GiftSuggestion] = []

    let maxResults = 6
    let minResults = 3

    private let existingItemNames: [String]
    private let suggestionService: GiftSuggestionServiceProtocol
    private let metadataService: ProductMetadataServiceProtocol
    private let authService: AuthenticateServiceProtocol
    private let countryProvider: CountryProviding

    init(
        existingItemNames: [String],
        suggestionService: GiftSuggestionServiceProtocol = GiftSuggestionService(),
        metadataService: ProductMetadataServiceProtocol = ProductMetadataService(),
        authService: AuthenticateServiceProtocol = AuthenticateService(),
        countryProvider: CountryProviding = LocationManager.shared
    ) {
        self.existingItemNames = existingItemNames
        self.suggestionService = suggestionService
        self.metadataService = metadataService
        self.authService = authService
        self.countryProvider = countryProvider
    }

    func start() async {
        do {
            let interests = try await authService.getUserInfo()?.interests ?? []
            if interests.isEmpty {
                phase = .needsInterests
                return
            }
        } catch {
            phase = .error(error.localizedDescription)
            return
        }
        await generate()
    }

    func saveInterestsAndContinue(_ interestIds: [String]) async {
        guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else {
            phase = .error("User session not found.")
            return
        }
        do {
            try await authService.updateUserInterests(userId: userId, interests: interestIds)
            await generate()
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    func generate() async {
        phase = .loading
        suggestions = []

        let user = try? await authService.getUserInfo()
        let interestIds = user?.interests ?? []
        let interestNames = GiftSuggestionInputBuilder.interestNames(fromIds: interestIds)
        // Social sign-up writes a placeholder dateOfBirth of "now", which yields age 0.
        // Treat an implausibly-low age as unknown so the prompt omits it rather than
        // telling the model the owner is 0 years old.
        let rawAge = user.map { GiftSuggestionInputBuilder.age(from: $0.dateOfBirth) } ?? nil
        let age = (rawAge ?? 0) >= 1 ? rawAge : nil

        let country = await countryProvider.resolveCountryName()

        let ideas: [GiftIdea]
        do {
            ideas = try await suggestionService.fetchIdeas(
                interests: interestNames,
                age: age,
                existingItemNames: existingItemNames,
                country: country
            )
        } catch {
            phase = .error(error.localizedDescription)
            return
        }

        await validate(ideas: ideas)

        if suggestions.count >= minResults {
            phase = .results
        } else {
            phase = .empty
        }
    }

    /// Validate candidate links concurrently (bounded), publishing each success as it arrives.
    /// Stops once `maxResults` have validated.
    private func validate(ideas: [GiftIdea]) async {
        let concurrency = 3
        var index = 0

        while index < ideas.count && suggestions.count < maxResults {
            let batch = ideas[index..<min(index + concurrency, ideas.count)]
            index += batch.count

            let validated: [GiftSuggestion] = await withTaskGroup(of: GiftSuggestion?.self) { group in
                for idea in batch {
                    group.addTask { [metadataService] in
                        guard let metadata = try? await metadataService.fetchMetadata(from: idea.link),
                              metadata.imageUrl?.isEmpty == false
                        else { return nil }
                        return GiftSuggestion(idea: idea, metadata: metadata)
                    }
                }
                var found: [GiftSuggestion] = []
                for await result in group {
                    if let result { found.append(result) }
                }
                return found
            }

            for suggestion in validated where suggestions.count < maxResults {
                suggestions.append(suggestion)
            }
        }
    }
}
