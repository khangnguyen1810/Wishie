# Share Context

## Important Instructions for Implementation

- Follow the project dev rules: no comments, no debug statements (`print`, `console.log`), no TODO markers, functional/immutable data patterns where applicable.
- Use `WorkSans` font via `.wishies(_ weight:, _ size:)`, `.lightYellow1` as the screen background, and `WishieButton` for the primary save action.
- All Firestore writes use `db.collection(WishieConstants.firebaseUserPath).document(userId)`.
- The `userid` key in `UserDefaults` is accessed via `WishieConstants.userIdKey`.
- New AppStorage key for interests setup completion: `"hasCompletedInterestsSetup"`.
- In `checkToken()`, do not bypass setup for existing sessions; derive `hasCompletedInterestsSetup` from persisted user profile data so returning users with incomplete setup are routed to `interestsSetup`.

## Reused Existing Functions/Utilities

- `WishieButton`: Primary action button — `Wishie/CustomView/WishieButton.swift`
- `BaseWishieScreen`: Screen wrapper with background and top bar slot — `Wishie/Screens/BaseWishieScreen.swift`
- `TopAppBar`: Three-slot navigation bar component — `Wishie/Screens/BaseWishieScreen.swift`
- `AuthenticateServiceProtocol` / `AuthenticateService`: Service layer for Firestore user operations — `Wishie/Services/AuthenticateService.swift`
- `WishieConstants.userIdKey`: Canonical UserDefaults key for the current user's Firebase UID — `Wishie/Constants/WishieConstants.swift`
- `WishieConstants.firebaseUserPath`: Canonical Firestore collection path `"users"` — `Wishie/Constants/WishieConstants.swift`
- `Color(hex:)`: Hex initializer for `Color` — `Wishie/Helper/ColorExtension.swift`
- `AuthViewModel.userInfo`: Provides the currently loaded `UserModel` including existing `interests` — `Wishie/Screens/Auth/AuthViewModel.swift`

## Shared Contracts

### Entities

- `HobbyItem`: Represents a single selectable hobby.
  - `id: String` — unique identifier (e.g., `"gym_fitness"`)
  - `name: String` — display name (e.g., `"Gym & Fitness"`)
  - `emoji: String` — single emoji prefix (e.g., `"🏋️"`)
  - Conforms to `Identifiable`, `Hashable`

- `HobbyCategory`: Represents a named group of hobbies.
  - `id: String` — unique identifier (e.g., `"active_sports"`)
  - `title: String` — display title (e.g., `"Active & Sports"`)
  - `items: [HobbyItem]` — hobbies in this category
  - Conforms to `Identifiable`

- `UserModel` (updated): Adds `interests: [String]` and `hasCompletedInterestsSetup: Bool` decoded from Firestore. Defaults to `[]` and `false`.

### Interfaces

- `AuthenticateServiceProtocol` (updated): Adds `func updateUserInterests(userId: String, interests: [String]) async throws` that persists both interests and setup completion state.

### DTOs

- N/A — interests are persisted as a plain `[String]` array (array of `HobbyItem.id`) directly in Firestore.

---

