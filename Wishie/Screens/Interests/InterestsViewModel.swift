import Foundation

@MainActor
final class InterestsViewModel: ObservableObject {
    @Published var selectedInterestIds: Set<String>
    @Published var isLoading: Bool = false
    @Published var isSaveSuccess: Bool = false
    @Published var errorMessage: String = ""

    let categories: [HobbyCategory] = hobbyCategories
    private let authService: AuthenticateServiceProtocol

    init(existingInterests: [String] = [], authService: AuthenticateServiceProtocol = AuthenticateService()) {
        self.selectedInterestIds = Set(existingInterests)
        self.authService = authService
    }

    func toggle(item: HobbyItem) {
        if selectedInterestIds.contains(item.id) {
            selectedInterestIds.remove(item.id)
        } else {
            selectedInterestIds.insert(item.id)
        }
    }

    func isSelected(_ item: HobbyItem) -> Bool {
        selectedInterestIds.contains(item.id)
    }

    func populate(existingInterests: [String]) {
        selectedInterestIds = Set(existingInterests)
    }

    func saveInterests() async {
        guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else {
            errorMessage = "User session not found."
            return
        }
        isLoading = true
        errorMessage = ""
        do {
            try await authService.updateUserInterests(userId: userId, interests: Array(selectedInterestIds))
            isLoading = false
            isSaveSuccess = true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
