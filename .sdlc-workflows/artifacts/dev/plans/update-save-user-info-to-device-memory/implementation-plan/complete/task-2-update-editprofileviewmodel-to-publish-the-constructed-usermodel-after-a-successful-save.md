# Task 2: Update EditProfileViewModel to publish the constructed UserModel after a successful save

- [ ] 2.1: In `Wishie/Screens/Profile/EditProfileViewModel.swift` UPDATE:
  - Add `@Published var updatedUser: UserModel? = nil` after `@Published var isSaveSuccess: Bool = false`.
  - Add `private var email: String = ""` after `@Published var existingAvatarUrl: String? = nil`.
  - In `populate(from user: UserModel)`, add `email = user.email` to capture the user's email for later use in constructing the updated `UserModel`.
  - In `saveProfile()`, on partial failures (e.g., avatar upload fails but profile fields update), still update `updatedUser` with the fields that succeeded. Do NOT skip updating the cache just because one operation failed. For example:
    ```swift
    var model = UserModel()
    model.firstName = firstName.trimmingCharacters(in: .whitespaces)
    model.lastName = lastName.trimmingCharacters(in: .whitespaces)
    model.email = email
    model.phone = phone
    model.dateOfBirth = dateOfBirth
    model.avatarUrl = avatarUrl
    updatedUser = model
    isSaveSuccess = true
    ```
    This code runs after `authService.updateUserInfo(...)` succeeds. If avatar upload beforehand failed, `avatarUrl` will still contain the `existingAvatarUrl` (not updated), and that's correct — the cache will reflect what was actually persisted.

