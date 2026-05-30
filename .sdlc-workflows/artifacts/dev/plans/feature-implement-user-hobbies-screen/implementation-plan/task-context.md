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

# Task 1: Data Layer — Model and Service Updates

- [ ] 1.1: In `Wishie/Models/UserModel.swift` UPDATE:
  - Add `var interests: [String] = []` property to `UserModel`.
  - Add `var hasCompletedInterestsSetup: Bool = false` property to `UserModel`.
  - In `init(dictionary:)`, decode `interests` as `dictionary["interests"] as? [String] ?? []`.
  - In `init(dictionary:)`, decode `hasCompletedInterestsSetup` as `dictionary["hasCompletedInterestsSetup"] as? Bool ?? false`.

- [ ] 1.2: In `Wishie/Models/HobbyCategory.swift` CREATE:
  - Define `struct HobbyItem: Identifiable, Hashable` with fields `id: String`, `name: String`, `emoji: String`.
  - Define `struct HobbyCategory: Identifiable` with fields `id: String`, `title: String`, `items: [HobbyItem]`.
  - Define a top-level `let hobbyCategories: [HobbyCategory]` constant with all 6 categories and their items:
    - `id: "active_sports"`, title: `"Active & Sports"`: `HobbyItem(id: "sports", name: "Sports", emoji: "🏅")`, `HobbyItem(id: "gym_fitness", name: "Gym & Fitness", emoji: "🏋️")`, `HobbyItem(id: "yoga_meditation", name: "Yoga & Meditation", emoji: "🧘")`, `HobbyItem(id: "hiking_trekking", name: "Hiking & Trekking", emoji: "🥾")`, `HobbyItem(id: "cycling", name: "Cycling", emoji: "🚴")`, `HobbyItem(id: "swimming", name: "Swimming", emoji: "🏊")`
    - `id: "creative"`, title: `"Creative"`: `HobbyItem(id: "reading", name: "Reading", emoji: "📚")`, `HobbyItem(id: "drawing_painting", name: "Drawing & Painting", emoji: "🎨")`, `HobbyItem(id: "photography", name: "Photography", emoji: "📸")`, `HobbyItem(id: "writing_journaling", name: "Writing & Journaling", emoji: "✍️")`, `HobbyItem(id: "music", name: "Music", emoji: "🎵")`, `HobbyItem(id: "crafting_diy", name: "Crafting & DIY", emoji: "🧶")`
    - `id: "entertainment_tech"`, title: `"Entertainment & Tech"`: `HobbyItem(id: "gaming", name: "Gaming", emoji: "🎮")`, `HobbyItem(id: "movies_series", name: "Watching Movies & Series", emoji: "🎬")`, `HobbyItem(id: "podcasts", name: "Podcasts", emoji: "🎙️")`, `HobbyItem(id: "anime_manga", name: "Anime & Manga", emoji: "🌸")`
    - `id: "food_drink"`, title: `"Food & Drink"`: `HobbyItem(id: "cooking_baking", name: "Cooking & Baking", emoji: "🍳")`, `HobbyItem(id: "food_exploring", name: "Food Exploring", emoji: "🍜")`, `HobbyItem(id: "coffee_tea", name: "Coffee & Tea", emoji: "☕")`
    - `id: "travel_outdoor"`, title: `"Travel & Outdoor"`: `HobbyItem(id: "traveling", name: "Traveling", emoji: "✈️")`, `HobbyItem(id: "camping", name: "Camping", emoji: "⛺")`, `HobbyItem(id: "nature_gardening", name: "Nature & Gardening", emoji: "🌿")`
    - `id: "selfcare_lifestyle"`, title: `"Self-care & Lifestyle"`: `HobbyItem(id: "beauty_skincare", name: "Beauty & Skincare", emoji: "💆")`, `HobbyItem(id: "fashion_styling", name: "Fashion & Styling", emoji: "👗")`, `HobbyItem(id: "collecting", name: "Collecting", emoji: "🗄️")`, `HobbyItem(id: "dancing", name: "Dancing", emoji: "💃")`

- [ ] 1.3: In `Wishie/Services/AuthenticateService.swift` UPDATE:
  - Add `func updateUserInterests(userId: String, interests: [String]) async throws` to `AuthenticateServiceProtocol`.
  - Implement in `AuthenticateService`: call `try await db.collection(WishieConstants.firebaseUserPath).document(userId).updateData(["interests": interests, "hasCompletedInterestsSetup": true])`.

---

# Task 2: State & Navigation — AppState and Coordinator Updates

- [ ] 2.1: In `Wishie/Models/AppState.swift` UPDATE:
  - Add `case interestsSetup` to the `AppState` enum, placing it between `unauthenticated` and `authenticated`.
  - The `requiresAuthentication` computed property `switch` must handle the new case — `interestsSetup` returns `false`.

- [ ] 2.2: In `Wishie/Screens/RootNavigationAnimations.swift` UPDATE:
  - Add transition cases to `animationFor(transition:)` for:
    - `(.unauthenticated, .interestsSetup)` → `authToHome`
    - `(.interestsSetup, .authenticated)` → `authToHome`

- [ ] 2.3: In `Wishie/Coordinator/RootNavigationCoordinator.swift` UPDATE:
  - Add `@AppStorage("hasCompletedInterestsSetup") private var hasCompletedInterestsSetup: Bool = false` alongside the existing `hasCompletedOnboarding` property.
  - Add `func completeInterestsSetup()` that sets `hasCompletedInterestsSetup = true` then calls `updateAppState()`.
  - Update `deriveAppState(isLoggedIn:)`: inside the `isLoggedIn && !userId.isEmpty` branch, add `if !hasCompletedInterestsSetup { return .interestsSetup }` before the final `return .authenticated(userId: userId)`.

- [ ] 2.4: In `Wishie/Screens/Auth/AuthViewModel.swift` UPDATE:
  - In `checkToken()`, inside the `Task` block after the successful `getIDToken(forcingRefresh:)` call and BEFORE `await MainActor.run { self.isLoggedIn = true }`, fetch latest user profile data and set `UserDefaults.standard.set(userInfo.hasCompletedInterestsSetup, forKey: "hasCompletedInterestsSetup")`.
  - If the Firestore field is missing for legacy users, rely on `UserModel` default `false` so those users are sent to `interestsSetup` on app reopen.

- [ ] 2.5: In `Wishie/Screens/MainView.swift` UPDATE:
  - Add a `case .interestsSetup:` branch in the `switch rootNavigationCoordinator.appState` block.
  - Render `InterestsSelectionView()` injected with `.environmentObject(authViewModel)` and `.transition(.opacity)`.

---

# Task 3: Interests Feature — ViewModel

- [ ] 3.1: In `Wishie/Screens/Interests/InterestsViewModel.swift` CREATE:
  - `@MainActor final class InterestsViewModel: ObservableObject`
  - `@Published var selectedInterestIds: Set<String>`
  - `@Published var isLoading: Bool = false`
  - `@Published var isSaveSuccess: Bool = false`
  - `@Published var errorMessage: String = ""`
  - `let categories: [HobbyCategory] = hobbyCategories` (uses `hobbyCategories` constant from task 1.2)
  - `private let authService: AuthenticateServiceProtocol`
  - `init(existingInterests: [String] = [], authService: AuthenticateServiceProtocol = AuthenticateService())` — initializes `selectedInterestIds` as `Set(existingInterests)`.
  - `func toggle(item: HobbyItem)`: if `selectedInterestIds.contains(item.id)`, remove it; otherwise insert it.
  - `func isSelected(_ item: HobbyItem) -> Bool`: returns `selectedInterestIds.contains(item.id)`.
  - `func saveInterests() async`: guard `userId` from `UserDefaults.standard.string(forKey: WishieConstants.userIdKey)` else set `errorMessage = "User session not found."` and return; set `isLoading = true`, `errorMessage = ""`; call `try await authService.updateUserInterests(userId: userId, interests: Array(selectedInterestIds))`; on success set `isLoading = false`, `isSaveSuccess = true`; on catch set `isLoading = false`, `errorMessage = error.localizedDescription`.

---

# Task 4: Interests Feature — View

- [ ] 4.1: In `Wishie/Screens/Interests/InterestsSelectionView.swift` CREATE:
  - `struct InterestsSelectionView: View`
  - `@EnvironmentObject var rootNavigationCoordinator: RootNavigationCoordinator`
  - `@EnvironmentObject var authViewModel: AuthViewModel`
  - `@StateObject private var viewModel: InterestsViewModel` — initialized via `init()` as `_viewModel = StateObject(wrappedValue: InterestsViewModel())`.
  - In `body`, use `BaseWishieScreen` with a `TopAppBar` center slot displaying `Text("Your Interests").font(.wishies(.bold, 20))`.
  - Inside a `ScrollView(.vertical)`, render a `VStack(alignment: .leading, spacing: 24)` with one section per `HobbyCategory` from `viewModel.categories`:
    - Section header: `Text(category.title).font(.wishies(.bold, 16))`.
    - Chip grid: `LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10)` iterating over `category.items` and rendering each as `HobbyChipView` (from task 4.2), passing `isSelected: viewModel.isSelected(item)` and `onTap: { viewModel.toggle(item: item) }`.
  - Below the `ScrollView`, render `WishieButton(title: "Save & Continue", enabled: !viewModel.isLoading)` whose action is `Task { await viewModel.saveInterests() }`.
  - When `viewModel.errorMessage` is non-empty, display it below the button as `Text(viewModel.errorMessage).font(.wishies(.regular, 14)).foregroundStyle(.red)`.
  - Use `.onChange(of: viewModel.isSaveSuccess)` — when `true`, call `rootNavigationCoordinator.completeInterestsSetup()`.
  - On first appearance via `.onAppear`, call `viewModel.populate(existingInterests: authViewModel.userInfo.interests)` to pre-fill selections from the already-loaded `UserModel`.

- [ ] 4.2: In `Wishie/CustomView/HobbyChipView.swift` CREATE:
  - `struct HobbyChipView: View`
  - `let item: HobbyItem`
  - `let isSelected: Bool`
  - `let onTap: () -> Void`
  - `body` renders a `Button(action: onTap)` containing `Text("\(item.emoji) \(item.name)").font(.wishies(.regular, 14)).padding(.horizontal, 14).padding(.vertical, 8)` inside a `Capsule`:
    - Unselected: `.fill(Color.white).strokeBorder(Color.lightYellow, lineWidth: 1.5)`, text `foregroundStyle(.black)`.
    - Selected: `.fill(Color.lightYellow)`, text `foregroundStyle(.black)`, `scaleEffect(isSelected ? 1.05 : 1.0)`.
  - Apply `.animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)` on the outermost view for chip toggle animation.

- [ ] 4.3: In `Wishie/Screens/Interests/InterestsViewModel.swift` UPDATE (add missing method from task 3.1):
  - Add `func populate(existingInterests: [String])`: sets `selectedInterestIds = Set(existingInterests)` — used by `InterestsSelectionView.onAppear` to pre-fill saved interests from `AuthViewModel.userInfo.interests`.
