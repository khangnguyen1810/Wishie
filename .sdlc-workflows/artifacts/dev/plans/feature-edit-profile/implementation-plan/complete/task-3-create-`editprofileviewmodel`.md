# Task 3: Create `EditProfileViewModel`

- [ ] 3.1: In `Wishie/Screens/Profile/EditProfileViewModel.swift` CREATE:
  - Define `@MainActor class EditProfileViewModel: ObservableObject`.
  - `@Published` properties: `firstName: String = ""`, `lastName: String = ""`, `phone: String = ""`, `dateOfBirth: Date = Date()`, `selectedAvatar: UIImage? = nil`, `existingAvatarUrl: String? = nil`, `isLoading: Bool = false`, `errorMessage: String = ""`, `isSaveSuccess: Bool = false`.
  - `private let authService: AuthenticateServiceProtocol`.
  - `init(authService: AuthenticateServiceProtocol = AuthenticateService())` — assigns `self.authService = authService`.
  - `func populate(from user: UserModel)` — assigns `firstName = user.firstName`, `lastName = user.lastName`, `phone = user.phone`, `dateOfBirth = user.dateOfBirth`, `existingAvatarUrl = user.avatarUrl`.
  - Computed `var isValid: Bool` — returns `!firstName.trimmingCharacters(in: .whitespaces).isEmpty && !lastName.trimmingCharacters(in: .whitespaces).isEmpty`.
  - `func saveProfile() async`:
    - Guard `isValid`, else set `errorMessage = "First name and last name are required."` and `return`.
    - Guard `UserDefaults.standard.string(forKey: WishieConstants.userIdKey)` as non-nil `userId`, else set `errorMessage = "User session not found."` and `return`.
    - Set `isLoading = true` and `errorMessage = ""`.
    - In `do`: if `selectedAvatar` is non-nil, `let avatarUrl = try await authService.uploadAvatar(image: selectedAvatar!, userId: userId)`, else `let avatarUrl = existingAvatarUrl`; then `try await authService.updateUserInfo(userId: userId, firstName: firstName, lastName: lastName, phone: phone, dateOfBirth: dateOfBirth, avatarUrl: avatarUrl)`; set `isLoading = false` and `isSaveSuccess = true`.
    - In `catch`: set `isLoading = false` and `errorMessage = error.localizedDescription`.

