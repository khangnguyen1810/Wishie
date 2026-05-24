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

