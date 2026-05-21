# Refactor Root Navigation Flow - Task Context

## Share Context

### Important Instructions for Implementation

- Follow the no-comment rule from dev-rules: write clear, self-explanatory code without explanatory comments
- Maintain backward compatibility with existing `AuthViewModel` for auth operations (keep it as-is, only add coordinator)
- Keep `AppStorage("hasCompletedOnboarding")` as the source of truth for onboarding state
- LaunchScreen logic remains in `WishieApp.swift` with the existing `isActive` flag pattern
- All navigation state derivation happens in `RootNavigationCoordinator`, keeping views focused on rendering
- State transitions must complete within 500ms as per non-functional requirements
- This refactor is a preparatory foundation for future extensibility (MaintenanceMode, PaymentRequired states, etc.)

### Reused Existing Functions/Utilities

- `AuthViewModel.isLoggedIn` (published property): Indicates if user is authenticated. Located in [Wishie/Screens/Auth/AuthViewModel.swift](Wishie/Screens/Auth/AuthViewModel.swift)
- `AppStorage("hasCompletedOnboarding")`: Persists onboarding completion state. Used in [Wishie/WishieApp.swift](Wishie/WishieApp.swift)
- `UserDefaults.standard`: Persists authentication token (userid). Used by `AuthViewModel.checkToken()` method in [Wishie/Screens/Auth/AuthViewModel.swift](Wishie/Screens/Auth/AuthViewModel.swift)
- View models follow MVVM pattern with `@Published` properties for reactive updates
- SwiftUI `@EnvironmentObject` injection pattern for app-wide state access

## Shared Contracts

### Entities

- **AppState** (NEW): Enum representing root navigation states with type-safe associated values
  - Case 1: `.welcome` - User hasn't completed onboarding
  - Case 2: `.unauthenticated` - Completed onboarding but not logged in (shows LoginOrSignUpScreen)
  - Case 3: `.authenticated(userId: String)` - Logged in user with their unique identifier
  - Conforms to `Hashable` for use in SwiftUI state comparisons
  - Provides computed property `requiresAuthentication: Bool` returning true for `.unauthenticated` case

### Interfaces

- **RootNavigationCoordinator** (NEW): Observable state manager for root navigation
  - Scope: App-wide, injected at `WishieApp` level as `@StateObject`, shared via `@EnvironmentObject`
  - Observes: `AuthViewModel.isLoggedIn` and `AppStorage("hasCompletedOnboarding")`
  - Maintains: `@Published var appState: AppState` (derived from auth and onboarding state)
  - Public methods:
    - `completeOnboarding()`: Sets `hasCompletedOnboarding` to true and updates `appState`
    - `logout()`: Calls `AuthViewModel.logOut()` and updates `appState` to `.unauthenticated`
  - Private computed property: `deriveAppState() -> AppState` that synthesizes current state from sources

### DTOs

- No new DTOs required. Existing models used:
  - `SignUpRequest` from [Wishie/Models/SignUpRequest.swift](Wishie/Models/SignUpRequest.swift): User registration data
  - `UserModel` from [Wishie/Models/UserModel.swift](Wishie/Models/UserModel.swift): Authenticated user information
  - `Route` enum from [Wishie/Models/Route.swift](Wishie/Models/Route.swift): Nested navigation within HomeView (unchanged)

## Architectural Decisions & Patterns

- **State Centralization**: Single `RootNavigationCoordinator` aggregates two independent sources (auth + onboarding) into one `AppState` enum
- **Coordinator Pattern**: Separates navigation logic from view rendering; views are purely presentational
- **Observable Pattern**: Uses SwiftUI `@ObservableObject` with `@Published` for reactive state changes
- **Dependency Injection**: Coordinator injected via `@EnvironmentObject` for app-wide access without prop drilling
- **Animation Strategy**: Fixed animations per state transition defined in `RootNavigationAnimations` configuration
- **Incremental Migration**: Existing nested navigation (Route enum in HomeView) remains untouched; only root-level navigation is refactored

---

