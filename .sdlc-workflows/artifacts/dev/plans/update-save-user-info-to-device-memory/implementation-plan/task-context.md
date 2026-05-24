# Share Context

## Important Instructions for Implementation

- All `@Published` property mutations triggered by async operations must occur on `@MainActor` to remain consistent with SwiftUI published state rules.
- Cache updates (assigning to `authViewModel.userInfo`) must only occur after service calls complete successfully without throwing — never speculatively.
- On partial save failures (e.g., avatar upload fails but profile fields update), update cache with successful fields only; do not revert previously cached values. For example: if `firstName`, `lastName`, and `phone` update successfully but avatar upload fails, update these three fields in cache and preserve the existing `avatarUrl`.
- `EditProfileView` should display a loading state while receiving and initializing from the passed `UserModel`. Once initialization completes, display the editable form with populated values.
- Cache reads are not restricted; other screens may read `authViewModel.userInfo` to avoid independent network calls for displaying profile data (e.g., name, avatar on other screens). However, only `ProfileView` and `EditProfileView` are permitted to **write** to the cache.
- `EditProfileViewModel` is lifted from `EditProfileView` to `ProfileView` as `@StateObject` so `ProfileView` can observe `updatedUser` directly via `.onChange`.
- `ProfileViewModel` is fully removed; no other file may reference it after Task 4.
- `EditProfileView` changes from creating its own `@StateObject` view model to accepting an externally owned `@ObservedObject var viewModel: EditProfileViewModel`.

## Reused Existing Functions/Utilities

- `AuthViewModel.getUserInfo()`: Async `@MainActor` method that calls `authService.getUserInfo()` and assigns the result to `self.userInfo`. Located in `Wishie/Screens/Auth/AuthViewModel.swift`.
- `EditProfileViewModel.populate(from:)`: Populates view model fields from a `UserModel`. Located in `Wishie/Screens/Profile/EditProfileViewModel.swift`. Will be extended in Task 2 to also store `email`.
- `AuthenticateServiceProtocol.getUserInfo()`: Async throws service method returning `UserModel?`. Defined in `Wishie/Services/AuthenticateService.swift`.
- `AuthenticateServiceProtocol.updateUserInfo(userId:firstName:lastName:phone:dateOfBirth:avatarUrl:)`: Async throws service method that persists updated profile fields to Firestore. Defined in `Wishie/Services/AuthenticateService.swift`.

## Shared Contracts

### Entities

- `UserModel`: Represents an authenticated user's display data. Fields: `firstName: String` (default `""`), `lastName: String` (default `""`), `email: String` (default `""`), `phone: String` (default `""`), `password: String` (default `""`), `dateOfBirth: Date` (default `Date()`), `avatarUrl: String?` (default `nil`). Initialized via `UserModel()` (empty defaults) or `UserModel(dictionary: [String: Any])`. Defined in `Wishie/Models/UserModel.swift`. Linked tasks: Task 1.1, Task 2.1, Task 3.1, Task 3.2.

### Interfaces

- `AuthenticateServiceProtocol`: Service protocol for auth and user operations. Key methods used across tasks: `getUserInfo() async throws -> UserModel?`, `updateUserInfo(userId:firstName:lastName:phone:dateOfBirth:avatarUrl:) async throws`, `uploadAvatar(image:userId:) async throws -> String`. Defined in `Wishie/Services/AuthenticateService.swift`. Linked tasks: Task 1.1, Task 2.1.

### DTOs

_(none applicable)_

## Cross-Task Dependencies

- Task 2.1 depends on `AuthViewModel.userInfo` lifecycle behavior (from Task 1.1) to ensure edited profile cache state remains aligned with post-auth cached state.
- Task 3.1 depends on `EditProfileViewModel.updatedUser` publication contract (from Task 2.1) to update `authViewModel.userInfo` via `.onChange`.
- Task 3.2 depends on `ProfileView` ownership of `EditProfileViewModel` as `@StateObject` (from Task 3.1) to receive injected `@ObservedObject`.
- Task 4.1 depends on removal of all `ProfileViewModel` references in `ProfileView` (from Task 3.1) before deleting `ProfileViewModel.swift` and removing its Xcode project reference.

# Task 1: Update AuthViewModel to fetch and cache user info on auth lifecycle events

- [ ] 1.1: In `Wishie/Screens/Auth/AuthViewModel.swift` UPDATE:
  - Add `@Published var userInfoError: String = ""` after `@Published var forgotenEmail: String = ""`.
  - In the `login()` `receiveValue` closure, after `isLoggedIn = true`, add `Task { await self.getUserInfo() }`.
  - In the `signup()` `receiveValue` closure, after `isLoggedIn = true`, add `Task { await self.getUserInfo() }`.
  - In `checkToken()`, inside the `Task` block after `await MainActor.run { self.isLoggedIn = true }`, add `await self.getUserInfo()`.
  - In `logOut()`, after `isLoggedIn = false`, add `self.userInfo = UserModel()` and `self.userInfoError = ""`.
  - In `getUserInfo()`, replace the `catch` block body from `print(error.localizedDescription)` to `self.userInfoError = error.localizedDescription`.

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

# Task 3: Refactor ProfileView and EditProfileView to eliminate ProfileViewModel and network fetches

- [ ] 3.1: In `Wishie/Screens/Profile/ProfileView.swift` UPDATE:
  - Remove `@StateObject private var viewModel: ProfileViewModel = ProfileViewModel()`.
  - Add `@StateObject private var editViewModel: EditProfileViewModel = EditProfileViewModel()`.
  - Replace all references to `viewModel.userInfo` with `authViewModel.userInfo`.
  - Replace `viewModel.errorMessage` with `authViewModel.userInfoError`.
  - Remove `.showFullScreenDialog($viewModel.isLoading)` from the view body.
  - Remove `.task { await viewModel.fetchUserInfo() }` from the view body.
  - In `navigationDestination(for: Route.self)` for the `.editProfile` case, change `EditProfileView(userModel: viewModel.userInfo)` to `EditProfileView(userModel: authViewModel.userInfo, viewModel: editViewModel)` and remove the `.onDisappear { Task { await viewModel.fetchUserInfo() } }` block entirely.
  - Add `.onChange(of: editViewModel.updatedUser) { _, updated in if let updated { authViewModel.userInfo = updated } }` on the `NavigationStack`.

- [ ] 3.2: In `Wishie/Screens/Profile/EditProfileView.swift` UPDATE:
  - Change `@StateObject private var viewModel = EditProfileViewModel()` to `@ObservedObject var viewModel: EditProfileViewModel`.
  - Update the struct initializer to accept `userModel: UserModel` and `viewModel: EditProfileViewModel` as parameters, matching the updated call site in Task 3.1.
  - During `onAppear`, before calling `viewModel.populate(from: userModel)`, show a brief loading indicator if the `userModel` contains empty/default values (e.g., `firstName.isEmpty`). This provides visual feedback while the async initialization settles. Once `populate()` completes, the form will display populated values.

# Task 4: Delete ProfileViewModel

- [ ] 4.1: DELETE `Wishie/Screens/Profile/ProfileViewModel.swift` — fully replaced by reading `authViewModel.userInfo` directly in `ProfileView` (Task 3.1). Remove the corresponding file reference from `Wishie.xcodeproj/project.pbxproj` to keep the Xcode project clean.
