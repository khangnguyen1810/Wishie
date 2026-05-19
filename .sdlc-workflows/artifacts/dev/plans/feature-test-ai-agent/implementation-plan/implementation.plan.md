Refactor root navigation flow

# Requirement Context

## Current State

The Wishie iOS app currently has root navigation logic scattered across two files:

- `WishieApp.swift`: Entry point that manages app lifecycle and shows LaunchScreen then MainView
- `MainView.swift`: Contains navigation routing logic that conditionally renders views based on two separate state sources (AppStorage for onboarding, EnvironmentObject for auth)

Navigation states are determined by two independent sources of truth:

- `hasCompletedOnboarding` via AppStorage
- `authViewModel.isLoggedIn` via EnvironmentObject

Current navigation flow: WelcomeView → LoginOrSignUpScreen → HomeView

Transitions use basic SwiftUI animations (.opacity, .move), and the Route enum exists but only handles nested navigation within HomeView, not root navigation.

## Goals

1. **Centralize app state handling**: Create a unified state manager (RootNavigationCoordinator or similar) that consolidates navigation state from multiple sources and provides a single source of truth
2. **Improve transition animations**: Implement more sophisticated transition animations (scale, combined effects) with customizable timing and easing
3. **Make root navigation scalable**: Design a pattern that easily accommodates new root states without requiring modifications to the core navigation logic
4. **Separate navigation logic from UI rendering**: Extract navigation routing decisions into a dedicated coordinator/state manager, keeping views responsible only for rendering

## Risk & Mitigation

- **Risk**: Existing views depend on reading state directly (AppStorage, EnvironmentObject). **Mitigation**: Create adapter/bridge methods in the coordinator to expose state in backward-compatible way, or refactor incrementally.
- **Risk**: AuthViewModel is already an EnvironmentObject injected in WishieApp. **Mitigation**: Keep AuthViewModel for auth logic, extract navigation coordination into separate coordinator.
- **Risk**: Tests may depend on current navigation structure. **Mitigation**: New coordinator should be mockable and testable.

# Technical Specification Context

## Functional Requirements:

- System MUST centralize root navigation state into a single `NavigationCoordinator` (or similar) that aggregates `authViewModel.isLoggedIn`, `hasCompletedOnboarding`, and any future root navigation states
- System MUST determine navigation target (WelcomeView, LoginOrSignUpScreen, HomeView) based on unified state from the coordinator
- System MUST render appropriate root view (welcome, auth, or home) based on coordinator state
- System MUST support smooth transitions between root navigation states with customizable animations
- System MUST allow coordinator to be injected as an EnvironmentObject for access throughout the app hierarchy
- System MUST maintain backward compatibility with existing nested navigation (Route enum in HomeView)
- System MUST preserve existing onboarding flow (WelcomeView → OnboardingContainerView) and auth flow (LoginOrSignUpScreen)

## Non-Functional Requirements:

- System MUST respond to navigation state changes with animations completed within 500ms
- System MUST reduce navigation logic coupling by separating coordinator from view rendering
- System MUST support future root navigation states without requiring changes to core routing logic (easily extensible to support additional app states like MaintenanceMode, PaymentRequired, etc.)
- System MUST maintain performance with no observable lag when transitioning between states
- System MUST preserve all existing animations and add configurable animation options for new transitions

## Architectural Decisions (from Clarifications):

1. **State Representation**: Use a single `AppState` enum with associated values (e.g., `.welcome`, `.authenticated(userId: String)`, `.unauthenticated`) to represent navigation state. This provides type safety and valid state combinations.

2. **Animation Strategy**: Implement fixed animations per state transition (not globally configurable). Each transition will have a specific animation (e.g., `.move(edge: .trailing)` for auth→home, `.opacity` for welcome→auth) defined in a centralized animation configuration.

3. **LaunchScreen Integration**: Keep the LaunchScreen logic in `WishieApp.swift` using the `isActive` flag. The `RootNavigationCoordinator` will activate after the launch screen completes, managing only the post-launch navigation states.

4. **AuthViewModel Scope**: Keep `AuthViewModel` as-is for auth operations and state. The `RootNavigationCoordinator` will observe `authViewModel.isLoggedIn` and the onboarding flag (`AppStorage`) and derive navigation state from these sources.

5. **Implementation Priority**: Start with state centralization (creating the coordinator), then enhance animations, then ensure scalability for future states.

## Design Patterns & Implementation Notes:

- Create `RootNavigationCoordinator` as an `@Observable` or `@StateObject` class that:
  - Observes `AuthViewModel.isLoggedIn` and `AppStorage("hasCompletedOnboarding")`
  - Maintains `@Published var appState: AppState`
  - Provides public methods to update related state (e.g., `completeOnboarding()`)
- Update `WishieApp.swift` to:
  - Keep LaunchScreen display logic
  - Inject `RootNavigationCoordinator` as `@StateObject`
  - Pass coordinator as `@EnvironmentObject` to MainView
- Refactor `MainView.swift` to:
  - Remove navigation logic
  - Receive `appState` from coordinator
  - Render appropriate view based on `appState`
  - Apply defined animations for state transitions
- Create `AppState` enum in Models with cases:

  ```swift
  enum AppState: Hashable {
      case welcome
      case loginOrSignUp
      case authenticated(userId: String)
  }
  ```

- Define animation mappings in a dedicated configuration (e.g., `RootNavigationAnimations`)
