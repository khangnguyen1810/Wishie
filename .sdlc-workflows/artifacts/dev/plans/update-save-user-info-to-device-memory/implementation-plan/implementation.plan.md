Persist user info after login

# Requirement Context

## Current State

`AuthViewModel` has a `@Published var userInfo: UserModel` property and a `getUserInfo()` async method, but neither is triggered after login or signup. `ProfileViewModel` independently instantiates `AuthenticateService` and calls `getUserInfo()` — a full Firestore network request — every time `ProfileView` appears. After editing the profile in `EditProfileView`, `ProfileView.onDisappear` triggers a second `getUserInfo()` network call to refresh the display. There is no shared in-memory cache of `UserModel` between sessions or screens.

## Goals

- Fetch user info exactly once after login, signup, and session token validation, and store it in `AuthViewModel.userInfo` as the single in-memory source of truth.
- Eliminate repeated Firestore `getUserInfo()` calls in `ProfileViewModel` and post-edit refresh in `ProfileView`.
- After a successful profile edit, propagate the updated `UserModel` locally into `AuthViewModel.userInfo` without an additional network call.
- Clear cached user info on logout.

## Risk & Mitigation

- **Stale cache after edit**: If `EditProfileViewModel` constructs the updated `UserModel` from its own local field values and the upstream Firestore write fails partway through, the in-memory cache may diverge from the persisted state. Mitigation: only update the cache after `authService.updateUserInfo()` completes without throwing. On partial failures (e.g., profile fields update but avatar upload fails), update the cache with successful fields only and leave other fields unchanged.
- **Empty userInfo before first fetch completes**: During the async window between login and the `getUserInfo()` response, screens reading `authViewModel.userInfo` will display empty/default values. Mitigation: EditProfileView should display a loading state during this window, and ProfileView can display default/empty state or loading indicator as appropriate.
- **Concurrent cache updates**: If a user rapidly navigates between ProfileView and EditProfileView, concurrent update attempts may occur. Mitigation: use "last write wins" strategy — the most recent cache update will overwrite previous ones. This is acceptable for typical user workflows and avoids serialization complexity.

# Technical Specification Context

## Functional Requirements

- System MUST call `AuthViewModel.getUserInfo()` after a successful `login()` response sets `isLoggedIn = true`.
- System MUST call `AuthViewModel.getUserInfo()` after a successful `signup()` response sets `isLoggedIn = true`.
- System MUST call `AuthViewModel.getUserInfo()` inside `checkToken()` after the Firebase ID token refresh succeeds.
- System MUST reset `AuthViewModel.userInfo` to an empty `UserModel()` inside `logOut()`.
- System MUST have `ProfileView` read user info from `authViewModel.userInfo` (via `@EnvironmentObject`) instead of triggering a network fetch via `ProfileViewModel`.
- System MUST remove the `ProfileViewModel.fetchUserInfo()` network call and its associated `isLoading` / `errorMessage` published state used for the fetch.
- System MUST remove the `.task { await viewModel.fetchUserInfo() }` call from `ProfileView`.
- System MUST propagate the updated `UserModel` into `authViewModel.userInfo` after a successful profile save in `EditProfileViewModel`, without making an additional `getUserInfo()` network call.
- On partial save failures (e.g., profile fields update but avatar upload fails), update the cache with successful fields only; do not revert previously cached values.
- System MUST remove the `ProfileView.onDisappear` block that triggers `viewModel.fetchUserInfo()` after returning from `EditProfileView`.
- System MUST remove `ProfileViewModel` entirely; `ProfileView` will read user info directly from `authViewModel.userInfo` via `@EnvironmentObject`.
- System MUST add `@Published var userInfoError: String` to `AuthViewModel` to surface post-login fetch failures on `ProfileView`.
- System MUST add `@Published var updatedUser: UserModel?` to `EditProfileViewModel`; after a successful save, assign the locally constructed updated `UserModel` to this property.
- System MUST observe `viewModel.updatedUser` in `ProfileView` via `.onChange` and assign it to `authViewModel.userInfo` when non-nil.
- System MUST scope cache **writes** (updates) to `ProfileView` and `EditProfileView` only. **Reads** of `authViewModel.userInfo` are not restricted; other screens may safely read profile data from the cache if they currently fetch independently (e.g., screens displaying user name, avatar, or other profile fields).

## Non-Functional Requirements

- System MUST reduce Firestore `getUserInfo()` network calls to at most one per authenticated session (post-login fetch only).
- System MUST propagate profile edit cache updates on the main actor to remain consistent with SwiftUI `@Published` state rules.
- System MUST surface a post-login `getUserInfo()` failure as an error message visible on `ProfileView`, using `authViewModel.userInfoError`.
