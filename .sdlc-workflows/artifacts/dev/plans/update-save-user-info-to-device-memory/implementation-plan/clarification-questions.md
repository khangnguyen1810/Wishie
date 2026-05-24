# Clarification Questions Template

## Purpose

Record questions raised during planning and their confirmed answers to resolve ambiguities in task requirements, ensuring the implementation plan reflects verified decisions.

# Guide:

- NEVER add question's options into this file, keep context small.
- ONLY add questions and it's answer following the template below.

# Template

```
- [the question]:
[the answer and its brief reasoning]
```

# Clarification Questions:

- After removing `fetchUserInfo()` from `ProfileViewModel`, the class becomes empty. What should happen to it?
  Remove `ProfileViewModel` entirely. `ProfileView` will read `authViewModel.userInfo` directly via `@EnvironmentObject`, eliminating unnecessary boilerplate while keeping the view reactive to published state.

- If `getUserInfo()` fails after login (e.g., network error), how should the app behave?
  Surface the error. `AuthViewModel` will expose a `userInfoError: String` published property and `ProfileView` will display it, giving the user visibility into the failure.

- After a successful profile save in `EditProfileViewModel`, how should `authViewModel.userInfo` be updated?
  `EditProfileViewModel` publishes `updatedUser: UserModel?` after a successful save. `ProfileView` observes it via `.onChange` and writes the updated model into `authViewModel.userInfo`. This avoids injecting `AuthViewModel` into `EditProfileViewModel` and avoids an extra network call.

- Should any other screens beyond `ProfileView` and `EditProfileView` also consume `authViewModel.userInfo` from the cache?
  No. Scope is limited to `ProfileView` and `EditProfileView` only. Other screens are explicitly out of scope for this task.

- When EditProfileView receives an empty or incomplete UserModel during initialization, what should it display?
  Show a loading state while user data is being fetched. Once loading completes, display the user info. This provides visual feedback during the async data fetch window and prevents displaying incomplete or placeholder data.

- If profile update succeeds but avatar upload fails (or vice versa), how should the cache be updated?
  Update the cache with successful fields only (partial cache). If avatar upload fails but firstName/lastName updates succeed, keep the profile field updates in the cache and maintain the existing avatar URL. This prevents losing valid profile updates while handling partial failures gracefully.

- If a user rapidly navigates between ProfileView and EditProfileView with concurrent cache updates, what should happen?
  Use "last write wins" strategy — the most recent update overwrites previous ones. This is the simplest approach and acceptable for typical user workflows in this scope, avoiding the need for additional serialization complexity.

- Are there other screens in the app that display profile data (read-only, not editing)?
  Yes. Other screens display profile data but do not edit it. While the editing scope remains limited to ProfileView and EditProfileView, these read-only screens could benefit from the cached userInfo if they currently reference ProfileViewModel. Consider expanding scope slightly to have these screens read from authViewModel.userInfo instead of fetching independently.
