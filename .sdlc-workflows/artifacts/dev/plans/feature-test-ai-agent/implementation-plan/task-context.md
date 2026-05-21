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

# Task 1: Create AppState enum model [ ]

Establish the type-safe root navigation state representation that consolidates onboarding and authentication states.

- 1.1: In `Wishie/Models/AppState.swift` **CREATE**:
  - Create new file `AppState.swift` in [Wishie/Models/](Wishie/Models/) directory
  - Define `enum AppState: Hashable` with three cases:
    - `.welcome` - User hasn't completed onboarding
    - `.unauthenticated` - Completed onboarding, not authenticated (shows LoginOrSignUpScreen)
    - `.authenticated(userId: String)` - Authenticated user with their unique identifier as associated value
  - Add computed property `requiresAuthentication: Bool` that returns `true` for `.unauthenticated` case, `false` otherwise
  - Ensure enum conforms to `Hashable` protocol (required for SwiftUI state comparisons and as EnvironmentObject)
  - No public methods or additional properties needed

---

# Task 2: Create RootNavigationCoordinator [ ]

Build the centralized state manager that observes `AuthViewModel` and `AppStorage`, derives unified `AppState`, and provides state update methods.

- 2.1: In `Wishie/Screens/Auth/RootNavigationCoordinator.swift` **CREATE**:
  - Create new file `RootNavigationCoordinator.swift` in [Wishie/Screens/Auth/](Wishie/Screens/Auth/) directory (co-located with AuthViewModel)
  - Define `final class RootNavigationCoordinator: ObservableObject`:
    - Add property `@Published var appState: AppState = .welcome` (default state)
    - Add private property `@ObservedReading(\.isLoggedIn) private var isLoggedInInner: Bool` or use alternative observation pattern
    - Add private `@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false`
    - Add private property `private var authViewModel: AuthViewModel?` to hold weak reference
    - Add private property `private var cancellables = Set<AnyCancellable>()` for Combine subscriptions
  - Implement `init(authViewModel: AuthViewModel)` initializer:
    - Store weak reference to `authViewModel`
    - Set up observation of `authViewModel.$isLoggedIn` to trigger state updates when auth changes
    - Call `deriveAppState()` immediately to set initial state
    - Subscribe to `$hasCompletedOnboarding` changes (AppStorage publishes via ObjectWillChange)
  - Implement private method `private func deriveAppState()`:
    - If `hasCompletedOnboarding` is false, set `appState = .welcome`
    - Else if `isLoggedIn` is true and user ID can be retrieved, set `appState = .authenticated(userId: /* from AuthViewModel or UserDefaults */)`
    - Else set `appState = .unauthenticated`
    - Call `objectWillChange.send()` to trigger published update
  - Implement public method `func completeOnboarding()`:
    - Set `hasCompletedOnboarding = true`
    - Call `deriveAppState()` to update published state
  - Implement public method `func logout()`:
    - Call `authViewModel?.logOut()` (AuthViewModel already handles UserDefaults cleanup)
    - Set `appState = .unauthenticated`

- 2.2: In `Wishie/Screens/Auth/RootNavigationCoordinator.swift` **ADD** (continuation):
  - Add deinit to clean up Combine cancellables
  - Ensure thread safety for state derivation (use DispatchQueue.main for state updates if needed)
  - Add documentation comment describing coordinator's role as single source of truth for root navigation

---

# Task 3: Create RootNavigationAnimations configuration [ ]

Define animation mappings for state transitions to ensure consistent, performant transitions across the app.

- 3.1: In `Wishie/Screens/RootNavigationAnimations.swift` **CREATE**:
  - Create new file `RootNavigationAnimations.swift` in [Wishie/Screens/](Wishie/Screens/) directory
  - Define `enum RootNavigationAnimations` (or `struct RootNavigationAnimations` with static properties):
    - Add static property `let welcomeToAuth: Animation = .easeInOut(duration: 0.4)` for transition from welcome to auth
    - Add static property `let authToHome: Animation = .move(edge: .trailing).combined(with: .opacity)` for auth to authenticated
    - Add static property `let homeToWelcome: Animation = .easeInOut(duration: 0.4)` for logout back to welcome
    - Add static property `let defaultDuration: Double = 0.4` for reference
  - Add static method `static func animationFor(transition: (from: AppState, to: AppState)) -> Animation` that:
    - Matches transition tuples (from, to) and returns appropriate animation
    - Returns `.easeInOut(duration: 0.4)` as fallback for undefined transitions
    - Pattern matching handles `.welcome → .unauthenticated`, `.unauthenticated → .authenticated`, `.authenticated → .unauthenticated`, etc.

---

# Task 4: Update WishieApp.swift [ ]

Inject `RootNavigationCoordinator` as `@StateObject` and pass it to views via `@EnvironmentObject`. Maintain existing LaunchScreen logic.

- 4.1: In [Wishie/WishieApp.swift](Wishie/WishieApp.swift) **UPDATE**:
  - Add import statement `import Combine` if not already present
  - Add new property `@StateObject private var rootNavigationCoordinator: RootNavigationCoordinator` (declared after `@StateObject private var authViewModel`)
  - Modify the `body` computed property:
    - Before initializing `RootNavigationCoordinator`, replace the initializer in `body` to pass `authViewModel` to the coordinator: `@StateObject private var rootNavigationCoordinator: RootNavigationCoordinator = RootNavigationCoordinator(authViewModel: /* needs to be resolved */)`
    - This requires restructuring: Create `rootNavigationCoordinator` after `authViewModel` initialization, passing `authViewModel` to its init
  - Update the `environmentObject` chain in the ZStack/body to add: `.environmentObject(rootNavigationCoordinator)` after `.environmentObject(authViewModel)`
  - Keep all existing code: LaunchScreen rendering with `isActive` flag, Firebase initialization, onAppear animation timing
  - Ensure animations for `authViewModel.isLoggedIn` and `hasCompletedOnboarding` are preserved (these now trigger through coordinator's observed state)

- 4.2: In [Wishie/WishieApp.swift](Wishie/WishieApp.swift) **UPDATE** (alternative if direct init is problematic):
  - If `@StateObject` initialization cannot directly pass `authViewModel`, use a workaround:
    - Initialize `rootNavigationCoordinator` with a placeholder in property declaration
    - In `body.onAppear` or immediately, create new instance and assign with proper authViewModel reference
    - Or use `@StateObject` initialization closure: `@StateObject private var rootNavigationCoordinator = { let authVM = AuthViewModel(); return RootNavigationCoordinator(authViewModel: authVM) }()` (but this creates duplicate AuthViewModel, so prefer explicit handling)
  - Ensure solution maintains single AuthViewModel instance

---

# Task 5: Refactor MainView.swift [ ]

Remove local navigation logic; render views based on `RootNavigationCoordinator.appState` with defined animations. Simplify view structure.

- 5.1: In [Wishie/Screens/MainView.swift](Wishie/Screens/MainView.swift) **UPDATE**:
  - Remove property `@AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false` (no longer needed here)
  - Remove property `@EnvironmentObject var authViewModel: AuthViewModel` (still have access via coordinator; if needed, can keep for AuthViewModel operations, but recommended removal)
  - Add new property `@EnvironmentObject var rootNavigationCoordinator: RootNavigationCoordinator`
  - Replace entire `body` with simplified conditional rendering based on `rootNavigationCoordinator.appState`:
    ```swift
    var body: some View {
        switch rootNavigationCoordinator.appState {
        case .welcome:
            WelcomeView()
                .transition(.opacity)
        case .unauthenticated:
            LoginOrSignUpScreen()
                .transition(.move(edge: .leading))
        case .authenticated(let userId):
            HomeView()
                .transition(.move(edge: .trailing))
        }
    }
    ```
  - Replace `.transition()` modifiers with calls to `RootNavigationAnimations.animationFor()` if animations are extracted to separate layer, or use defined animations directly
  - Wrap entire switch in animation modifier if needed: `.animation(.easeInOut(duration: 0.4), value: rootNavigationCoordinator.appState)` to animate between states

- 5.2: In [Wishie/Screens/MainView.swift](Wishie/Screens/MainView.swift) **VALIDATE**:
  - Ensure `WelcomeView()` is used (should have no parameters or existing parameters unchanged)
  - Ensure `LoginOrSignUpScreen()` is used (should have no parameters or existing parameters unchanged)
  - Ensure `HomeView()` is used (should receive `authViewModel` if it's a dependency; add `.environmentObject(authViewModel)` if coordinator is not injecting auth model)
  - Check that nested navigation via `Route` enum in HomeView remains untouched (HomeView manages its own NavigationStack internally)
  - If `LoginOrSignUpScreen` or other auth screens read from coordinator, add `.environmentObject(rootNavigationCoordinator)` for their state updates

---

# Task 6: Cross-Platform Testing & Validation [ ]

Verify state transitions, animations, and backward compatibility without introducing regressions.

- 6.1: Manual validation (no automated tests per project guidelines):
  - Launch app and verify LaunchScreen displays for ~0.5 seconds, then MainView appears
  - Cold start without onboarding: should show WelcomeView
  - Click "Let's get started": should transition to onboarding flow (maintained in `OnboardingContainerView`)
  - Complete onboarding: should transition to LoginOrSignUpScreen with `.move(edge: .leading)` animation
  - Login successfully: should transition to HomeView with `.move(edge: .trailing)` animation
  - Verify HomeView's nested Route navigation still works (create list, scan QR, etc.)
  - Logout from HomeView: should return to LoginOrSignUpScreen
  - Re-login: should show HomeView again without affecting onboarding flag
  - Force restart app (simulate): should restore to previous state (HomeView if logged in, LoginOrSignUpScreen if not but onboarded, WelcomeView otherwise)

- 6.2: Code review checklist:
  - [ ] `AppState` enum is Hashable and covers all navigation paths
  - [ ] `RootNavigationCoordinator` properly observes both `authViewModel.isLoggedIn` and `hasCompletedOnboarding`
  - [ ] `RootNavigationCoordinator.deriveAppState()` correctly handles all state combinations
  - [ ] `WishieApp.swift` injects both `authViewModel` and `rootNavigationCoordinator` as EnvironmentObjects
  - [ ] `MainView.swift` uses only `rootNavigationCoordinator.appState` for rendering decisions
  - [ ] Animations complete within 500ms (verify visually or via Xcode performance tools)
  - [ ] No console warnings about missing EnvironmentObjects
  - [ ] LaunchScreen logic remains functional and timing preserved
  - [ ] Onboarding flow (WelcomeView → OnboardingContainerView) still functions
  - [ ] Existing nested navigation (HomeView → Route destinations) is untouched

---

# Task 7: Cross-task Dependencies & Integration Points

- Task 1 (AppState model) is a prerequisite for Task 2
- Task 2 (RootNavigationCoordinator) depends on Task 1 and `AuthViewModel` from [Wishie/Screens/Auth/AuthViewModel.swift](Wishie/Screens/Auth/AuthViewModel.swift)
- Task 3 (RootNavigationAnimations) is independent but used in Task 5
- Task 4 (WishieApp update) depends on Task 1 and Task 2; must be completed before Task 5
- Task 5 (MainView refactor) depends on Tasks 1, 2, 3, and 4; final step in navigation refactor
- Task 6 (Testing & validation) validates all tasks 1-5

## File Dependency Graph

```
WishieApp.swift
  ├── imports AuthViewModel (existing)
  ├── creates @StateObject RootNavigationCoordinator (new - Task 2)
  ├── injects AuthViewModel + RootNavigationCoordinator as EnvironmentObject
  └── displays MainView

MainView.swift (refactored - Task 5)
  ├── receives @EnvironmentObject RootNavigationCoordinator (new - Task 2)
  ├── reads @Published appState: AppState (new - Task 1)
  ├── renders WelcomeView, LoginOrSignUpScreen, or HomeView based on appState
  └── applies animations from RootNavigationAnimations (new - Task 3)

RootNavigationCoordinator (new - Task 2)
  ├── observes AuthViewModel.isLoggedIn (existing)
  ├── observes AppStorage("hasCompletedOnboarding") (existing)
  ├── derives AppState (new - Task 1)
  ├── provides completeOnboarding() method (called by OnboardingContainerView)
  └── provides logout() method (called by HomeView settings)

AppState enum (new - Task 1)
  └── used by RootNavigationCoordinator and MainView for type-safe state representation

RootNavigationAnimations (new - Task 3)
  └── provides animation definitions for MainView state transitions
```

---

# Implementation Priority & Execution Order

1. **Phase 1**: Task 1 (AppState model) - standalone, no dependencies
2. **Phase 2**: Task 2 (RootNavigationCoordinator) - depends only on AppState + existing AuthViewModel
3. **Phase 3**: Task 3 (RootNavigationAnimations) - independent configuration, can be done in parallel with Task 2
4. **Phase 4**: Task 4 (WishieApp update) - depends on Task 1 and Task 2
5. **Phase 5**: Task 5 (MainView refactor) - depends on all previous tasks; final integration step
6. **Phase 6**: Task 6 (Testing & validation) - validates all changes
