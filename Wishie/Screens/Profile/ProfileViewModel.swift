import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userInfo: UserModel = UserModel()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""

    private let authService: AuthenticateServiceProtocol

    init(authService: AuthenticateServiceProtocol = AuthenticateService()) {
        self.authService = authService
    }

    func fetchUserInfo() async {
        isLoading = true
        errorMessage = ""
        do {
            guard let result = try await authService.getUserInfo() else {
                isLoading = false
                return
            }
            userInfo = result
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
