import Foundation
import UIKit

@MainActor
class EditProfileViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var phone: String = ""
    @Published var dateOfBirth: Date = Date()
    @Published var selectedAvatar: UIImage? = nil
    @Published var existingAvatarUrl: String? = nil
    private var email: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var isSaveSuccess: Bool = false
    @Published var updatedUser: UserModel? = nil

    private let authService: AuthenticateServiceProtocol

    init(authService: AuthenticateServiceProtocol = AuthenticateService()) {
        self.authService = authService
    }

    func populate(from user: UserModel) {
        firstName = user.firstName
        lastName = user.lastName
        email = user.email
        phone = user.phone
        dateOfBirth = user.dateOfBirth
        existingAvatarUrl = user.avatarUrl
    }

    var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func saveProfile() async {
        guard isValid else {
            errorMessage = "First name and last name are required."
            return
        }
        guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else {
            errorMessage = "User session not found."
            return
        }
        isLoading = true
        errorMessage = ""
        do {
            let avatarUrl: String?
            if let image = selectedAvatar {
                avatarUrl = try await authService.uploadAvatar(image: image, userId: userId)
            } else {
                avatarUrl = existingAvatarUrl
            }
            try await authService.updateUserInfo(
                userId: userId,
                firstName: firstName,
                lastName: lastName,
                phone: phone,
                dateOfBirth: dateOfBirth,
                avatarUrl: avatarUrl
            )
            var model = UserModel()
            model.firstName = firstName.trimmingCharacters(in: .whitespaces)
            model.lastName = lastName.trimmingCharacters(in: .whitespaces)
            model.email = email
            model.phone = phone
            model.dateOfBirth = dateOfBirth
            model.avatarUrl = avatarUrl
            updatedUser = model
            isLoading = false
            isSaveSuccess = true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
